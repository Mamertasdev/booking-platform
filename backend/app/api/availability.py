from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.appointment import Appointment
from app.models.service import Service
from app.schemas.appointment import (
    AppointmentCreate,
    AppointmentResponse,
    AppointmentUpdateStatus,
)

router = APIRouter()


@router.get("/appointments", response_model=list[AppointmentResponse])
def get_appointments(
    business_id: int | None = Query(default=None),
    specialist_id: int | None = Query(default=None),
    db: Session = Depends(get_db)
):
    query = db.query(Appointment)

    if business_id is not None:
        query = query.filter(Appointment.business_id == business_id)

    if specialist_id is not None:
        query = query.filter(Appointment.specialist_id == specialist_id)

    return query.all()


@router.get("/appointments/{appointment_id}", response_model=AppointmentResponse)
def get_appointment(appointment_id: int, db: Session = Depends(get_db)):
    appointment = (
        db.query(Appointment)
        .filter(Appointment.id == appointment_id)
        .first()
    )

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    return appointment


@router.post("/appointments", response_model=AppointmentResponse)
def create_appointment(payload: AppointmentCreate, db: Session = Depends(get_db)):
    service = (
        db.query(Service)
        .filter(Service.id == payload.service_id)
        .filter(Service.business_id == payload.business_id)
        .filter(Service.is_active == True)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    appointment_end = payload.appointment_start + timedelta(minutes=service.duration_minutes)

    appointment = Appointment(
        business_id=payload.business_id,
        specialist_id=payload.specialist_id,
        service_id=payload.service_id,
        client_full_name=payload.client_full_name,
        client_email=payload.client_email,
        client_phone=payload.client_phone,
        notes=payload.notes,
        appointment_start=payload.appointment_start,
        appointment_end=appointment_end,
        status="confirmed",
        is_active=True,
    )
    db.add(appointment)
    db.commit()
    db.refresh(appointment)
    return appointment


@router.put("/appointments/{appointment_id}/status", response_model=AppointmentResponse)
def update_appointment_status(
    appointment_id: int,
    payload: AppointmentUpdateStatus,
    db: Session = Depends(get_db)
):
    appointment = (
        db.query(Appointment)
        .filter(Appointment.id == appointment_id)
        .first()
    )

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    appointment.status = payload.status

    db.commit()
    db.refresh(appointment)
    return appointment