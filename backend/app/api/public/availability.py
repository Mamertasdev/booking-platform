from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.business import Business
from app.models.service import Service
from app.models.specialist import Specialist
from app.services.availability import (
    filter_past_slots_for_today,
    filter_slots_by_appointments,
    filter_slots_by_exceptions,
    generate_time_slots,
    get_appointments_for_day,
    get_exceptions_for_day,
    get_service_duration_minutes,
    get_working_hours_for_day,
)

router = APIRouter()


@router.get("/availability")
def get_public_availability(
    business_id: int = Query(...),
    specialist_id: int = Query(...),
    service_id: int = Query(...),
    target_date: date = Query(...),
    db: Session = Depends(get_db),
):
    business = (
        db.query(Business)
        .filter(Business.id == business_id)
        .filter(Business.is_active == True)
        .first()
    )

    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    specialist = (
        db.query(Specialist)
        .filter(Specialist.id == specialist_id)
        .filter(Specialist.business_id == business_id)
        .filter(Specialist.role.in_(["owner", "specialist"]))
        .filter(Specialist.is_active == True)
        .first()
    )

    if not specialist:
        raise HTTPException(status_code=404, detail="Specialist not found")

    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .filter(Service.business_id == business_id)
        .filter(Service.is_active == True)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

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

    if not service_duration_minutes:
        raise HTTPException(status_code=404, detail="Service duration not found")

    slots = []

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
        "slots": [
            {
                "start_time": str(item["start_time"]),
                "end_time": str(item["end_time"]),
            }
            for item in slots
        ],
    }