from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.core.security import hash_password, verify_password
from app.models.specialist import Specialist
from app.schemas.specialist import SpecialistCreate, SpecialistLogin, SpecialistResponse

router = APIRouter()


@router.get("/specialists", response_model=list[SpecialistResponse])
def get_specialists(
    business_id: int | None = Query(default=None),
    db: Session = Depends(get_db)
):
    query = db.query(Specialist)

    if business_id is not None:
        query = query.filter(Specialist.business_id == business_id)

    return query.all()

@router.get("/specialists/{specialist_id}", response_model=SpecialistResponse)
def get_specialist(specialist_id: int, db: Session = Depends(get_db)):
    specialist = (
        db.query(Specialist)
        .filter(Specialist.id == specialist_id)
        .first()
    )

    if not specialist:
        raise HTTPException(status_code=404, detail="Specialist not found")

    return specialist


@router.post("/specialists", response_model=SpecialistResponse)
def create_specialist(payload: SpecialistCreate, db: Session = Depends(get_db)):
    existing_specialist = (
        db.query(Specialist)
        .filter(Specialist.username == payload.username)
        .first()
    )

    if existing_specialist:
        raise HTTPException(status_code=400, detail="Username already exists")

    specialist = Specialist(
        business_id=payload.business_id,
        username=payload.username,
        password_hash=hash_password(payload.password),
        full_name=payload.full_name,
        is_active=True,
    )
    db.add(specialist)
    db.commit()
    db.refresh(specialist)
    return specialist

@router.post("/specialists/login")
def login_specialist(payload: SpecialistLogin, db: Session = Depends(get_db)):
    specialist = (
        db.query(Specialist)
        .filter(Specialist.username == payload.username)
        .first()
    )

    if not specialist:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not specialist.is_active:
        raise HTTPException(status_code=403, detail="Specialist account is inactive")

    if not verify_password(payload.password, specialist.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return {
        "message": "Login successful",
        "specialist_id": specialist.id,
        "business_id": specialist.business_id,
        "username": specialist.username,
        "full_name": specialist.full_name,
    }