from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.appointment import create_appointment_internal
from app.api.deps import get_db
from app.schemas.appointment import AppointmentCreate, AppointmentResponse

router = APIRouter()


@router.post("/book", response_model=AppointmentResponse)
def public_book(payload: AppointmentCreate, db: Session = Depends(get_db)):
    return create_appointment_internal(payload=payload, db=db, current_user=None)