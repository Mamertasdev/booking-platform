from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_active_user, require_admin, get_db
from app.core.security import hash_password
from app.models.specialist import Specialist
from app.schemas.specialist import SpecialistCreate, SpecialistResponse

router = APIRouter()


@router.get("/specialists", response_model=list[SpecialistResponse])
def get_specialists(
    business_id: int | None = Query(default=None),
    include_inactive: bool = Query(default=False),
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    query = db.query(Specialist)

    if current_user.role != "admin":
        business_id = current_user.business_id

    if business_id is not None:
        query = query.filter(Specialist.business_id == business_id)

    if not include_inactive:
        query = query.filter(Specialist.is_active == True)

    return query.order_by(Specialist.full_name.asc()).all()


@router.get("/specialists/{specialist_id}", response_model=SpecialistResponse)
def get_specialist(
    specialist_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    specialist = (
        db.query(Specialist)
        .filter(Specialist.id == specialist_id)
        .first()
    )

    if not specialist:
        raise HTTPException(status_code=404, detail="Specialist not found")

    if current_user.role != "admin":
        if specialist.id != current_user.id:
            raise HTTPException(status_code=403, detail="Not allowed")

    return specialist


@router.post("/specialists", response_model=SpecialistResponse)
def create_specialist(
    payload: SpecialistCreate,
    current_user: Specialist = Depends(require_admin),
    db: Session = Depends(get_db)
):
    existing_user = (
        db.query(Specialist)
        .filter(Specialist.username == payload.username.strip())
        .first()
    )

    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")

    specialist = Specialist(
        business_id=payload.business_id,
        username=payload.username.strip(),
        password_hash=hash_password(payload.password),
        full_name=payload.full_name.strip(),
        role=payload.role,
        is_active=True,
    )

    db.add(specialist)
    db.commit()
    db.refresh(specialist)
    return specialist


@router.put("/specialists/{specialist_id}/disable", response_model=SpecialistResponse)
def disable_specialist(
    specialist_id: int,
    current_user: Specialist = Depends(require_admin),
    db: Session = Depends(get_db)
):
    specialist = (
        db.query(Specialist)
        .filter(Specialist.id == specialist_id)
        .first()
    )

    if not specialist:
        raise HTTPException(status_code=404, detail="Specialist not found")

    specialist.is_active = False

    db.commit()
    db.refresh(specialist)
    return specialist