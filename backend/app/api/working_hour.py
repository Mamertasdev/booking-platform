from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.working_hour import WorkingHour
from app.schemas.working_hour import WorkingHourCreate, WorkingHourResponse, WorkingHourUpdate

router = APIRouter()


@router.get("/working-hours", response_model=list[WorkingHourResponse])
def get_working_hours(
    business_id: int | None = Query(default=None),
    specialist_id: int | None = Query(default=None),
    db: Session = Depends(get_db)
):
    query = db.query(WorkingHour)

    if business_id is not None:
        query = query.filter(WorkingHour.business_id == business_id)

    if specialist_id is not None:
        query = query.filter(WorkingHour.specialist_id == specialist_id)

    return query.all()


@router.post("/working-hours", response_model=WorkingHourResponse)
def create_working_hour(payload: WorkingHourCreate, db: Session = Depends(get_db)):
    working_hour = WorkingHour(
        business_id=payload.business_id,
        specialist_id=payload.specialist_id,
        weekday=payload.weekday,
        start_time=payload.start_time,
        end_time=payload.end_time,
        is_active=True,
    )
    db.add(working_hour)
    db.commit()
    db.refresh(working_hour)
    return working_hour

@router.put("/working-hours/{working_hour_id}", response_model=WorkingHourResponse)
def update_working_hour(
    working_hour_id: int,
    payload: WorkingHourUpdate,
    db: Session = Depends(get_db)
):
    working_hour = (
        db.query(WorkingHour)
        .filter(WorkingHour.id == working_hour_id)
        .first()
    )

    if not working_hour:
        raise HTTPException(status_code=404, detail="Working hour not found")

    working_hour.weekday = payload.weekday
    working_hour.start_time = payload.start_time
    working_hour.end_time = payload.end_time
    working_hour.is_active = payload.is_active

    db.commit()
    db.refresh(working_hour)
    return working_hour