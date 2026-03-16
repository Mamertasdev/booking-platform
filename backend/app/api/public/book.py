from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.appointment import AppointmentCreate, AppointmentResponse
from app.api.appointment import create_appointment

router = APIRouter()


@router.post("/book", response_model=AppointmentResponse)
def public_book(payload: AppointmentCreate, db: Session = Depends(get_db)):
    return create_appointment(payload, db)