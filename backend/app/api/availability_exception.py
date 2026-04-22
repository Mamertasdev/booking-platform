from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import (
    ROLE_ADMIN,
    ROLE_OWNER,
    ROLE_SPECIALIST,
    get_current_active_user,
    get_db,
)
from app.models.availability_exception import AvailabilityException
from app.models.specialist import Specialist
from app.schemas.availability_exception import (
    AvailabilityExceptionCreate,
    AvailabilityExceptionResponse,
    AvailabilityExceptionUpdate,
)

router = APIRouter()


def _require_user_business_id(user: Specialist) -> int:
    if user.business_id is None:
        raise HTTPException(
            status_code=400,
            detail="User has no business assigned",
        )
    return user.business_id


def _normalize_scope(
    *,
    business_id: int | None,
    specialist_id: int | None,
    current_user: Specialist,
) -> tuple[int | None, int | None]:
    if current_user.role == ROLE_ADMIN:
        return business_id, specialist_id

    if current_user.role == ROLE_OWNER:
        return _require_user_business_id(current_user), specialist_id

    if current_user.role == ROLE_SPECIALIST:
        return _require_user_business_id(current_user), current_user.id

    raise HTTPException(status_code=403, detail="Not allowed")


def _ensure_access(
    current_user: Specialist,
    item: AvailabilityException,
):
    if current_user.role == ROLE_ADMIN:
        return

    if current_user.role == ROLE_OWNER:
        if item.business_id != _require_user_business_id(current_user):
            raise HTTPException(status_code=403, detail="Not allowed")
        return

    if current_user.role == ROLE_SPECIALIST:
        if (
            item.business_id != _require_user_business_id(current_user)
            or item.specialist_id != current_user.id
        ):
            raise HTTPException(status_code=403, detail="Not allowed")
        return

    raise HTTPException(status_code=403, detail="Not allowed")


@router.get("/availability-exceptions", response_model=list[AvailabilityExceptionResponse])
def get_availability_exceptions(
    business_id: int | None = None,
    specialist_id: int | None = None,
    include_inactive: bool = False,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    business_id, specialist_id = _normalize_scope(
        business_id=business_id,
        specialist_id=specialist_id,
        current_user=current_user,
    )

    query = db.query(AvailabilityException)

    if not include_inactive:
        query = query.filter(AvailabilityException.is_active == True)

    if business_id is not None:
        query = query.filter(AvailabilityException.business_id == business_id)

    if specialist_id is not None:
        query = query.filter(AvailabilityException.specialist_id == specialist_id)

    return query.order_by(AvailabilityException.start_datetime.asc()).all()


@router.post("/availability-exceptions", response_model=AvailabilityExceptionResponse)
def create_availability_exception(
    payload: AvailabilityExceptionCreate,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    business_id, specialist_id = _normalize_scope(
        business_id=payload.business_id,
        specialist_id=payload.specialist_id,
        current_user=current_user,
    )

    if business_id is None or specialist_id is None:
        raise HTTPException(status_code=400, detail="Invalid scope")

    item = AvailabilityException(
        business_id=business_id,
        specialist_id=specialist_id,
        start_datetime=payload.start_datetime,
        end_datetime=payload.end_datetime,
        reason=payload.reason,
        is_active=True,
    )

    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.put("/availability-exceptions/{exception_id}", response_model=AvailabilityExceptionResponse)
def update_availability_exception(
    exception_id: int,
    payload: AvailabilityExceptionUpdate,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    item = (
        db.query(AvailabilityException)
        .filter(AvailabilityException.id == exception_id)
        .first()
    )

    if not item:
        raise HTTPException(status_code=404, detail="Availability exception not found")

    _ensure_access(current_user, item)

    item.start_datetime = payload.start_datetime
    item.end_datetime = payload.end_datetime
    item.reason = payload.reason
    item.is_active = payload.is_active

    db.commit()
    db.refresh(item)
    return item


@router.put("/availability-exceptions/{exception_id}/disable", response_model=AvailabilityExceptionResponse)
def disable_availability_exception(
    exception_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    item = (
        db.query(AvailabilityException)
        .filter(AvailabilityException.id == exception_id)
        .first()
    )

    if not item:
        raise HTTPException(status_code=404, detail="Availability exception not found")

    _ensure_access(current_user, item)

    item.is_active = False

    db.commit()
    db.refresh(item)
    return item