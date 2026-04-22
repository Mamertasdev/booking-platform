from datetime import date, datetime, time, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.deps import (
    ROLE_ADMIN,
    ROLE_OWNER,
    ROLE_SPECIALIST,
    get_current_active_user,
    get_db,
)
from app.models.appointment import Appointment
from app.models.service import Service
from app.models.specialist import Specialist
from app.schemas.appointment import (
    AppointmentCreate,
    AppointmentReschedule,
    AppointmentResponse,
    AppointmentUpdateStatus,
)
from app.services.availability import (
    filter_past_slots_for_today,
    filter_slots_by_appointments,
    filter_slots_by_exceptions,
    generate_time_slots,
    get_appointments_for_day,
    get_exceptions_for_day,
    get_working_hours_for_day,
)

router = APIRouter()


def _require_user_business_id(current_user: Specialist) -> int:
    if current_user.business_id is None:
        raise HTTPException(
            status_code=400,
            detail="Current user is not assigned to a business",
        )
    return current_user.business_id


def _normalize_appointment_scope(
    *,
    business_id: int | None,
    specialist_id: int | None,
    current_user: Specialist | None,
) -> tuple[int | None, int | None]:
    if current_user is None:
        return business_id, specialist_id

    if current_user.role == ROLE_ADMIN:
        return business_id, specialist_id

    if current_user.role == ROLE_OWNER:
        owner_business_id = _require_user_business_id(current_user)
        return owner_business_id, specialist_id

    if current_user.role == ROLE_SPECIALIST:
        specialist_business_id = _require_user_business_id(current_user)
        return specialist_business_id, current_user.id

    raise HTTPException(status_code=403, detail="Not allowed")


def _ensure_can_access_appointment(
    current_user: Specialist,
    appointment: Appointment,
):
    if current_user.role == ROLE_ADMIN:
        return

    if current_user.role == ROLE_OWNER:
        owner_business_id = _require_user_business_id(current_user)
        if appointment.business_id != owner_business_id:
            raise HTTPException(status_code=403, detail="Not allowed")
        return

    if current_user.role == ROLE_SPECIALIST:
        specialist_business_id = _require_user_business_id(current_user)
        if (
            appointment.business_id != specialist_business_id
            or appointment.specialist_id != current_user.id
        ):
            raise HTTPException(status_code=403, detail="Not allowed")
        return

    raise HTTPException(status_code=403, detail="Not allowed")


def create_appointment_internal(
    payload: AppointmentCreate,
    db: Session,
    current_user: Specialist | None = None,
):
    business_id, specialist_id = _normalize_appointment_scope(
        business_id=payload.business_id,
        specialist_id=payload.specialist_id,
        current_user=current_user,
    )

    if business_id is None:
        raise HTTPException(status_code=400, detail="business_id is required")

    if specialist_id is None:
        raise HTTPException(status_code=400, detail="specialist_id is required")

    service = (
        db.query(Service)
        .filter(Service.id == payload.service_id)
        .filter(Service.business_id == business_id)
        .filter(Service.is_active == True)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    target_date = payload.appointment_start.date()

    working_hours = get_working_hours_for_day(
        db=db,
        business_id=business_id,
        specialist_id=specialist_id,
        target_date=target_date,
    )

    exceptions = get_exceptions_for_day(
        db=db,
        business_id=business_id,
        specialist_id=specialist_id,
        target_date=target_date,
    )

    appointments = get_appointments_for_day(
        db=db,
        business_id=business_id,
        specialist_id=specialist_id,
        target_date=target_date,
    )

    slots = []

    for item in working_hours:
        slots.extend(
            generate_time_slots(
                start_time=item.start_time,
                end_time=item.end_time,
                duration_minutes=service.duration_minutes,
            )
        )

    slots = filter_slots_by_exceptions(
        target_date=target_date,
        slots=slots,
        exceptions=exceptions,
    )

    slots = filter_slots_by_appointments(
        target_date=target_date,
        slots=slots,
        appointments=appointments,
    )

    slots = filter_past_slots_for_today(
        target_date=target_date,
        slots=slots,
    )

    slot_exists = any(
        slot["start_time"] == payload.appointment_start.time()
        for slot in slots
    )

    if not slot_exists:
        raise HTTPException(
            status_code=400,
            detail="Selected time slot is not available",
        )

    existing_appointment = (
        db.query(Appointment)
        .filter(Appointment.business_id == business_id)
        .filter(Appointment.specialist_id == specialist_id)
        .filter(Appointment.appointment_start == payload.appointment_start)
        .filter(Appointment.is_active == True)
        .first()
    )

    if existing_appointment:
        raise HTTPException(
            status_code=400,
            detail="Selected time slot is no longer available",
        )

    appointment_end = payload.appointment_start + timedelta(
        minutes=service.duration_minutes
    )

    appointment = Appointment(
        business_id=business_id,
        specialist_id=specialist_id,
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

    try:
        db.add(appointment)
        db.commit()
        db.refresh(appointment)
        return appointment
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Selected time slot is no longer available",
        )


@router.get("/appointments", response_model=list[AppointmentResponse])
def get_appointments(
    business_id: int | None = Query(default=None),
    specialist_id: int | None = Query(default=None),
    target_date: date | None = Query(default=None),
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    business_id, specialist_id = _normalize_appointment_scope(
        business_id=business_id,
        specialist_id=specialist_id,
        current_user=current_user,
    )

    query = db.query(Appointment).filter(Appointment.is_active == True)

    if business_id is not None:
        query = query.filter(Appointment.business_id == business_id)

    if specialist_id is not None:
        query = query.filter(Appointment.specialist_id == specialist_id)

    if target_date is not None:
        day_start = datetime.combine(target_date, time.min)
        day_end = datetime.combine(target_date, time.max)

        query = query.filter(Appointment.appointment_start >= day_start)
        query = query.filter(Appointment.appointment_start <= day_end)

    return query.order_by(Appointment.appointment_start.asc()).all()


@router.get("/appointments/{appointment_id}", response_model=AppointmentResponse)
def get_appointment(
    appointment_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    appointment = (
        db.query(Appointment)
        .filter(Appointment.id == appointment_id)
        .first()
    )

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    _ensure_can_access_appointment(current_user, appointment)
    return appointment


@router.post("/appointments", response_model=AppointmentResponse)
def create_appointment(
    payload: AppointmentCreate,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    return create_appointment_internal(
        payload=payload,
        db=db,
        current_user=current_user,
    )


@router.put("/appointments/{appointment_id}/status", response_model=AppointmentResponse)
def update_appointment_status(
    appointment_id: int,
    payload: AppointmentUpdateStatus,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    appointment = (
        db.query(Appointment)
        .filter(Appointment.id == appointment_id)
        .first()
    )

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    _ensure_can_access_appointment(current_user, appointment)

    appointment.status = payload.status

    db.commit()
    db.refresh(appointment)
    return appointment


@router.put("/appointments/{appointment_id}/cancel", response_model=AppointmentResponse)
def cancel_appointment(
    appointment_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    appointment = (
        db.query(Appointment)
        .filter(Appointment.id == appointment_id)
        .first()
    )

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    _ensure_can_access_appointment(current_user, appointment)

    appointment.status = "cancelled_by_admin"
    appointment.is_active = False

    db.commit()
    db.refresh(appointment)
    return appointment


@router.put("/appointments/{appointment_id}/reschedule", response_model=AppointmentResponse)
def reschedule_appointment(
    appointment_id: int,
    payload: AppointmentReschedule,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    appointment = (
        db.query(Appointment)
        .filter(Appointment.id == appointment_id)
        .first()
    )

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    _ensure_can_access_appointment(current_user, appointment)

    service = (
        db.query(Service)
        .filter(Service.id == appointment.service_id)
        .filter(Service.business_id == appointment.business_id)
        .filter(Service.is_active == True)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    target_date = payload.appointment_start.date()

    working_hours = get_working_hours_for_day(
        db=db,
        business_id=appointment.business_id,
        specialist_id=appointment.specialist_id,
        target_date=target_date,
    )

    exceptions = get_exceptions_for_day(
        db=db,
        business_id=appointment.business_id,
        specialist_id=appointment.specialist_id,
        target_date=target_date,
    )

    appointments = get_appointments_for_day(
        db=db,
        business_id=appointment.business_id,
        specialist_id=appointment.specialist_id,
        target_date=target_date,
    )

    appointments = [item for item in appointments if item.id != appointment.id]

    slots = []

    for item in working_hours:
        slots.extend(
            generate_time_slots(
                start_time=item.start_time,
                end_time=item.end_time,
                duration_minutes=service.duration_minutes,
            )
        )

    slots = filter_slots_by_exceptions(
        target_date=target_date,
        slots=slots,
        exceptions=exceptions,
    )

    slots = filter_slots_by_appointments(
        target_date=target_date,
        slots=slots,
        appointments=appointments,
    )

    slots = filter_past_slots_for_today(
        target_date=target_date,
        slots=slots,
    )

    slot_exists = any(
        slot["start_time"] == payload.appointment_start.time()
        for slot in slots
    )

    if not slot_exists:
        raise HTTPException(
            status_code=400,
            detail="Selected new time slot is not available",
        )

    existing_appointment = (
        db.query(Appointment)
        .filter(Appointment.business_id == appointment.business_id)
        .filter(Appointment.specialist_id == appointment.specialist_id)
        .filter(Appointment.appointment_start == payload.appointment_start)
        .filter(Appointment.id != appointment.id)
        .filter(Appointment.is_active == True)
        .first()
    )

    if existing_appointment:
        raise HTTPException(
            status_code=400,
            detail="Selected new time slot is no longer available",
        )

    appointment.appointment_start = payload.appointment_start
    appointment.appointment_end = payload.appointment_start + timedelta(
        minutes=service.duration_minutes
    )
    appointment.status = "confirmed"
    appointment.is_active = True

    try:
        db.commit()
        db.refresh(appointment)
        return appointment
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Selected new time slot is no longer available",
        )