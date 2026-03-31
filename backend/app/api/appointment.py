from datetime import time

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_active_user, get_db
from app.models.specialist import Specialist
from app.models.working_hour import WorkingHour
from app.schemas.working_hour import (
    WorkingHourCreate,
    WorkingHourResponse,
    WorkingHourUpdate,
)

router = APIRouter()


def time_ranges_overlap(
    start_a: time,
    end_a: time,
    start_b: time,
    end_b: time,
) -> bool:
    return start_a < end_b and start_b < end_a


def ensure_no_working_hour_overlap(
    db: Session,
    business_id: int,
    specialist_id: int,
    weekday: int,
    start_time: time,
    end_time: time,
    exclude_id: int | None = None,
):
    query = (
        db.query(WorkingHour)
        .filter(WorkingHour.business_id == business_id)
        .filter(WorkingHour.specialist_id == specialist_id)
        .filter(WorkingHour.weekday == weekday)
        .filter(WorkingHour.is_active == True)
    )

    if exclude_id is not None:
        query = query.filter(WorkingHour.id != exclude_id)

    existing_rows = query.all()

    for row in existing_rows:
        if time_ranges_overlap(
            start_time,
            end_time,
            row.start_time,
            row.end_time,
        ):
            raise HTTPException(
                status_code=400,
                detail="Working hour overlaps with an existing interval",
            )


@router.get("/working-hours", response_model=list[WorkingHourResponse])
def get_working_hours(
    business_id: int | None = Query(default=None),
    specialist_id: int | None = Query(default=None),
    include_inactive: bool = Query(default=False),
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    query = db.query(WorkingHour)

    if current_user.role != "admin":
        business_id = current_user.business_id
        specialist_id = current_user.id

    if business_id is not None:
        query = query.filter(WorkingHour.business_id == business_id)

    if specialist_id is not None:
        query = query.filter(WorkingHour.specialist_id == specialist_id)

    if not include_inactive:
        query = query.filter(WorkingHour.is_active == True)

    return (
        query.order_by(
            WorkingHour.weekday.asc(),
            WorkingHour.start_time.asc(),
        ).all()
    )


@router.get("/working-hours/{working_hour_id}", response_model=WorkingHourResponse)
def get_working_hour(
    working_hour_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    working_hour = (
        db.query(WorkingHour)
        .filter(WorkingHour.id == working_hour_id)
        .first()
    )

    if not working_hour:
        raise HTTPException(status_code=404, detail="Working hour not found")

    if current_user.role != "admin":
        if (
            working_hour.business_id != current_user.business_id
            or working_hour.specialist_id != current_user.id
        ):
            raise HTTPException(status_code=403, detail="Not allowed")

    return working_hour


@router.post("/working-hours", response_model=WorkingHourResponse)
def create_working_hour(
    payload: WorkingHourCreate,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    business_id = payload.business_id
    specialist_id = payload.specialist_id

    if current_user.role != "admin":
        business_id = current_user.business_id
        specialist_id = current_user.id

    ensure_no_working_hour_overlap(
        db=db,
        business_id=business_id,
        specialist_id=specialist_id,
        weekday=payload.weekday,
        start_time=payload.start_time,
        end_time=payload.end_time,
    )

    working_hour = WorkingHour(
        business_id=business_id,
        specialist_id=specialist_id,
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
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    working_hour = (
        db.query(WorkingHour)
        .filter(WorkingHour.id == working_hour_id)
        .first()
    )

    if not working_hour:
        raise HTTPException(status_code=404, detail="Working hour not found")

    if current_user.role != "admin":
        if (
            working_hour.business_id != current_user.business_id
            or working_hour.specialist_id != current_user.id
        ):
            raise HTTPException(status_code=403, detail="Not allowed")

    if payload.is_active:
        ensure_no_working_hour_overlap(
            db=db,
            business_id=working_hour.business_id,
            specialist_id=working_hour.specialist_id,
            weekday=payload.weekday,
            start_time=payload.start_time,
            end_time=payload.end_time,
            exclude_id=working_hour.id,
        )

    working_hour.weekday = payload.weekday
    working_hour.start_time = payload.start_time
    working_hour.end_time = payload.end_time
    working_hour.is_active = payload.is_active

    db.commit()
    db.refresh(working_hour)
    return working_hour


@router.put("/working-hours/{working_hour_id}/disable", response_model=WorkingHourResponse)
def disable_working_hour(
    working_hour_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    working_hour = (
        db.query(WorkingHour)
        .filter(WorkingHour.id == working_hour_id)
        .first()
    )

    if not working_hour:
        raise HTTPException(status_code=404, detail="Working hour not found")

    if current_user.role != "admin":
        if (
            working_hour.business_id != current_user.business_id
            or working_hour.specialist_id != current_user.id
        ):
            raise HTTPException(status_code=403, detail="Not allowed")

    working_hour.is_active = False

    db.commit()
    db.refresh(working_hour)
    return working_hour