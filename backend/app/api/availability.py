from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.services.availability import (
    filter_past_slots_for_today,
    filter_slots_by_appointments,
    filter_slots_by_exceptions,
    generate_time_slots,
    get_appointments_for_day,
    get_exceptions_for_day,
    get_service_duration_minutes,
    get_weekday,
    get_working_hours_for_day,
)

router = APIRouter()


@router.get("/availability")
def get_availability(
    business_id: int = Query(...),
    specialist_id: int = Query(...),
    service_id: int = Query(...),
    target_date: date = Query(...),
    db: Session = Depends(get_db),
):
    weekday = get_weekday(target_date)

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

    service_duration_minutes = get_service_duration_minutes(
        db=db,
        business_id=business_id,
        service_id=service_id,
    )

    slots = []

    if service_duration_minutes:
        for item in working_hours:
            slots.extend(
                generate_time_slots(
                    start_time=item.start_time,
                    end_time=item.end_time,
                    duration_minutes=service_duration_minutes,
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

    return {
        "business_id": business_id,
        "specialist_id": specialist_id,
        "service_id": service_id,
        "target_date": str(target_date),
        "weekday": weekday,
        "service_duration_minutes": service_duration_minutes,
        "working_hours": [
            {
                "id": item.id,
                "start_time": str(item.start_time),
                "end_time": str(item.end_time),
            }
            for item in working_hours
        ],
        "exceptions": [
            {
                "id": item.id,
                "start_datetime": item.start_datetime.isoformat(),
                "end_datetime": item.end_datetime.isoformat(),
                "reason": item.reason,
            }
            for item in exceptions
        ],
        "appointments": [
            {
                "id": item.id,
                "appointment_start": item.appointment_start.isoformat(),
                "appointment_end": item.appointment_end.isoformat(),
                "status": item.status,
                "client_full_name": item.client_full_name,
            }
            for item in appointments
        ],
        "slots": [
            {
                "start_time": str(item["start_time"]),
                "end_time": str(item["end_time"]),
            }
            for item in slots
        ],
    }