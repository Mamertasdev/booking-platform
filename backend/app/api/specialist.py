from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import (
    ROLE_ADMIN,
    ROLE_OWNER,
    ROLE_SPECIALIST,
    get_current_active_user,
    get_db,
    require_owner_or_admin,
)
from app.core.security import hash_password
from app.models.specialist import Specialist
from app.schemas.specialist import (
    SpecialistCreate,
    SpecialistResponse,
    SpecialistUpdate,
)

router = APIRouter()


def count_other_active_admins(
    db: Session,
    specialist_id_to_exclude: int,
) -> int:
    return (
        db.query(Specialist)
        .filter(Specialist.role == ROLE_ADMIN)
        .filter(Specialist.is_active == True)
        .filter(Specialist.id != specialist_id_to_exclude)
        .count()
    )


def get_specialist_or_404(db: Session, specialist_id: int) -> Specialist:
    specialist = (
        db.query(Specialist)
        .filter(Specialist.id == specialist_id)
        .first()
    )

    if not specialist:
        raise HTTPException(status_code=404, detail="Specialist not found")

    return specialist


def ensure_owner_business(current_user: Specialist) -> int:
    if current_user.business_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Owner must belong to a business",
        )

    return current_user.business_id


def ensure_can_access_specialist(
    current_user: Specialist,
    target_specialist: Specialist,
):
    if current_user.role == ROLE_ADMIN:
        return

    if current_user.role == ROLE_OWNER:
        owner_business_id = ensure_owner_business(current_user)

        if target_specialist.business_id != owner_business_id:
            raise HTTPException(status_code=403, detail="Not allowed")

        return

    if current_user.role == ROLE_SPECIALIST:
        if target_specialist.id != current_user.id:
            raise HTTPException(status_code=403, detail="Not allowed")

        return

    raise HTTPException(status_code=403, detail="Not allowed")


def normalize_is_bookable_for_role(role: str, is_bookable: bool) -> bool:
    if role == ROLE_ADMIN:
        return False

    return is_bookable


@router.get("/specialists", response_model=list[SpecialistResponse])
def get_specialists(
    business_id: int | None = Query(default=None),
    include_inactive: bool = Query(default=False),
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    query = db.query(Specialist)

    if current_user.role == ROLE_ADMIN:
        if business_id is not None:
            query = query.filter(Specialist.business_id == business_id)

    elif current_user.role == ROLE_OWNER:
        owner_business_id = ensure_owner_business(current_user)
        query = query.filter(Specialist.business_id == owner_business_id)

    elif current_user.role == ROLE_SPECIALIST:
        query = query.filter(Specialist.id == current_user.id)

    else:
        raise HTTPException(status_code=403, detail="Not allowed")

    if not include_inactive:
        query = query.filter(Specialist.is_active == True)

    return query.order_by(Specialist.full_name.asc()).all()


@router.get("/specialists/{specialist_id}", response_model=SpecialistResponse)
def get_specialist(
    specialist_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    specialist = get_specialist_or_404(db, specialist_id)
    ensure_can_access_specialist(current_user, specialist)
    return specialist


@router.post("/specialists", response_model=SpecialistResponse)
def create_specialist(
    payload: SpecialistCreate,
    current_user: Specialist = Depends(require_owner_or_admin),
    db: Session = Depends(get_db),
):
    existing_user = (
        db.query(Specialist)
        .filter(Specialist.username == payload.username.strip())
        .first()
    )

    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")

    role = payload.role.strip().lower()

    if current_user.role == ROLE_OWNER:
        owner_business_id = ensure_owner_business(current_user)

        if role != ROLE_SPECIALIST:
            raise HTTPException(
                status_code=403,
                detail="Owner can only create specialists",
            )

        business_id = owner_business_id

    else:
        business_id = payload.business_id

        if role != ROLE_ADMIN and business_id is None:
            raise HTTPException(
                status_code=400,
                detail="business_id is required for owner and specialist",
            )

    specialist = Specialist(
        business_id=business_id,
        username=payload.username.strip(),
        password_hash=hash_password(payload.password),
        full_name=payload.full_name.strip(),
        role=role,
        is_active=True,
        is_bookable=normalize_is_bookable_for_role(
            role=role,
            is_bookable=payload.is_bookable,
        ),
    )

    db.add(specialist)
    db.commit()
    db.refresh(specialist)
    return specialist


@router.put("/specialists/{specialist_id}", response_model=SpecialistResponse)
def update_specialist(
    specialist_id: int,
    payload: SpecialistUpdate,
    current_user: Specialist = Depends(require_owner_or_admin),
    db: Session = Depends(get_db),
):
    specialist = get_specialist_or_404(db, specialist_id)

    existing_user = (
        db.query(Specialist)
        .filter(Specialist.username == payload.username.strip())
        .filter(Specialist.id != specialist_id)
        .first()
    )

    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")

    new_role = payload.role.strip().lower()

    if current_user.role == ROLE_OWNER:
        owner_business_id = ensure_owner_business(current_user)

        if specialist.business_id != owner_business_id:
            raise HTTPException(status_code=403, detail="Not allowed")

        if specialist.role == ROLE_ADMIN:
            raise HTTPException(
                status_code=403,
                detail="Owner cannot manage admins",
            )

        if specialist.role == ROLE_OWNER and specialist.id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="Owner cannot manage another owner",
            )

        if specialist.id == current_user.id:
            if new_role != ROLE_OWNER:
                raise HTTPException(
                    status_code=400,
                    detail="You cannot change your own owner role",
                )
            business_id = owner_business_id
        else:
            if new_role != ROLE_SPECIALIST:
                raise HTTPException(
                    status_code=403,
                    detail="Owner can only assign specialist role",
                )
            business_id = owner_business_id

    else:
        if current_user.id == specialist.id and not payload.is_active:
            raise HTTPException(
                status_code=400,
                detail="You cannot disable your own account",
            )

        if current_user.id == specialist.id and new_role != ROLE_ADMIN:
            raise HTTPException(
                status_code=400,
                detail="You cannot change your own admin role",
            )

        removing_admin_privileges = (
            specialist.role == ROLE_ADMIN
            and (new_role != ROLE_ADMIN or not payload.is_active)
        )

        if removing_admin_privileges:
            other_active_admins = count_other_active_admins(
                db=db,
                specialist_id_to_exclude=specialist.id,
            )

            if other_active_admins == 0:
                raise HTTPException(
                    status_code=400,
                    detail="Cannot remove the last active admin",
                )

        business_id = payload.business_id

        if new_role != ROLE_ADMIN and business_id is None:
            raise HTTPException(
                status_code=400,
                detail="business_id is required for owner and specialist",
            )

    specialist.business_id = business_id
    specialist.username = payload.username.strip()
    specialist.full_name = payload.full_name.strip()
    specialist.role = new_role
    specialist.is_active = payload.is_active
    specialist.is_bookable = normalize_is_bookable_for_role(
        role=new_role,
        is_bookable=payload.is_bookable,
    )

    if payload.password is not None and payload.password.strip():
        specialist.password_hash = hash_password(payload.password.strip())

    db.commit()
    db.refresh(specialist)
    return specialist


@router.put("/specialists/{specialist_id}/disable", response_model=SpecialistResponse)
def disable_specialist(
    specialist_id: int,
    current_user: Specialist = Depends(require_owner_or_admin),
    db: Session = Depends(get_db),
):
    specialist = get_specialist_or_404(db, specialist_id)

    if current_user.role == ROLE_OWNER:
        owner_business_id = ensure_owner_business(current_user)

        if specialist.business_id != owner_business_id:
            raise HTTPException(status_code=403, detail="Not allowed")

        if specialist.role != ROLE_SPECIALIST:
            raise HTTPException(
                status_code=403,
                detail="Owner can only disable specialists",
            )

    else:
        if current_user.id == specialist.id:
            raise HTTPException(
                status_code=400,
                detail="You cannot disable your own account",
            )

        if specialist.role == ROLE_ADMIN:
            other_active_admins = count_other_active_admins(
                db=db,
                specialist_id_to_exclude=specialist.id,
            )

            if other_active_admins == 0:
                raise HTTPException(
                    status_code=400,
                    detail="Cannot disable the last active admin",
                )

    specialist.is_active = False
    specialist.is_bookable = False

    db.commit()
    db.refresh(specialist)
    return specialist