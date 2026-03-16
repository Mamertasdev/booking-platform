from datetime import date, datetime, time, timedelta

from sqlalchemy.orm import Session

from app.models.appointment import Appointment
from app.models.availability_exception import AvailabilityException
from app.models.service import Service
from app.models.working_hour import WorkingHour


def get_weekday(target_date: date) -> int:
    return target_date.weekday()


def get_working_hours_for_day(
    db: Session,
    business_id: int,
    specialist_id: int,
    target_date: date,
):
    weekday = get_weekday(target_date)

    return (
        db.query(WorkingHour)
        .filter(WorkingHour.business_id == business_id)
        .filter(WorkingHour.specialist_id == specialist_id)
        .filter(WorkingHour.weekday == weekday)
        .filter(WorkingHour.is_active == True)
        .all()
    )


def get_exceptions_for_day(
    db: Session,
    business_id: int,
    specialist_id: int,
    target_date: date,
):
    day_start = datetime.combine(target_date, time.min)
    day_end = datetime.combine(target_date, time.max)

    return (
        db.query(AvailabilityException)
        .filter(AvailabilityException.business_id == business_id)
        .filter(AvailabilityException.specialist_id == specialist_id)
        .filter(AvailabilityException.is_active == True)
        .filter(AvailabilityException.start_datetime <= day_end)
        .filter(AvailabilityException.end_datetime >= day_start)
        .all()
    )


def get_service_duration_minutes(
    db: Session,
    business_id: int,
    service_id: int,
) -> int | None:
    service = (
        db.query(Service)
        .filter(Service.business_id == business_id)
        .filter(Service.id == service_id)
        .filter(Service.is_active == True)
        .first()
    )

    if not service:
        return None

    return service.duration_minutes


def generate_time_slots(
    start_time: time,
    end_time: time,
    duration_minutes: int,
):
    slots = []

    current_start = datetime.combine(date.today(), start_time)
    range_end = datetime.combine(date.today(), end_time)
    duration = timedelta(minutes=duration_minutes)

    while current_start + duration <= range_end:
        current_end = current_start + duration

        slots.append(
            {
                "start_time": current_start.time(),
                "end_time": current_end.time(),
            }
        )

        current_start += duration

    return slots


def get_appointments_for_day(
    db: Session,
    business_id: int,
    specialist_id: int,
    target_date: date,
):
    day_start = datetime.combine(target_date, time.min)
    day_end = datetime.combine(target_date, time.max)

    return (
        db.query(Appointment)
        .filter(Appointment.business_id == business_id)
        .filter(Appointment.specialist_id == specialist_id)
        .filter(Appointment.is_active == True)
        .filter(Appointment.appointment_start <= day_end)
        .filter(Appointment.appointment_end >= day_start)
        .all()
    )


def ranges_overlap(
    start_a: datetime,
    end_a: datetime,
    start_b: datetime,
    end_b: datetime,
) -> bool:
    return start_a < end_b and start_b < end_a


def filter_slots_by_exceptions(
    target_date: date,
    slots: list[dict],
    exceptions: list,
):
    filtered_slots = []

    for slot in slots:
        slot_start = datetime.combine(target_date, slot["start_time"])
        slot_end = datetime.combine(target_date, slot["end_time"])

        overlaps_exception = False

        for exception in exceptions:
            if ranges_overlap(
                slot_start,
                slot_end,
                exception.start_datetime.replace(tzinfo=None),
                exception.end_datetime.replace(tzinfo=None),
            ):
                overlaps_exception = True
                break

        if not overlaps_exception:
            filtered_slots.append(slot)

    return filtered_slots


def filter_slots_by_appointments(
    target_date: date,
    slots: list[dict],
    appointments: list,
):
    filtered_slots = []

    for slot in slots:
        slot_start = datetime.combine(target_date, slot["start_time"])
        slot_end = datetime.combine(target_date, slot["end_time"])

        overlaps_appointment = False

        for appointment in appointments:
            appointment_start = appointment.appointment_start.replace(tzinfo=None)
            appointment_end = appointment.appointment_end.replace(tzinfo=None)

            if ranges_overlap(
                slot_start,
                slot_end,
                appointment_start,
                appointment_end,
            ):
                overlaps_appointment = True
                break

        if not overlaps_appointment:
            filtered_slots.append(slot)

    return filtered_slots