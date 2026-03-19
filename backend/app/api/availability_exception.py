from datetime import date, datetime, time

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.availability_exception import AvailabilityException
from app.schemas.availability_exception import (
    AvailabilityExceptionCreate,
    AvailabilityExceptionResponse,
    AvailabilityExceptionUpdate,
)

router = APIRouter()


@router.get("/availability-exceptions", response_model=list[AvailabilityExceptionResponse])
def get_availability_exceptions(
    business_id: int | None = Query(default=None),
    specialist_id: int | None = Query(default=None),
    target_date: date | None = Query(default=None),
    include_inactive: bool = Query(default=False),
    db: Session = Depends(get_db)
):
    query = db.query(AvailabilityException)

    if business_id is not None:
        query = query.filter(AvailabilityException.business_id == business_id)

    if specialist_id is not None:
        query = query.filter(AvailabilityException.specialist_id == specialist_id)

    if target_date is not None:
        day_start = datetime.combine(target_date, time.min)
        day_end = datetime.combine(target_date, time.max)

        query = query.filter(AvailabilityException.start_datetime <= day_end)
        query = query.filter(AvailabilityException.end_datetime >= day_start)

    if not include_inactive:
        query = query.filter(AvailabilityException.is_active == True)

    return query.order_by(AvailabilityException.start_datetime.asc()).all()


@router.get("/availability-exceptions/{exception_id}", response_model=AvailabilityExceptionResponse)
def get_availability_exception(
    exception_id: int,
    db: Session = Depends(get_db)
):
    exception = (
        db.query(AvailabilityException)
        .filter(AvailabilityException.id == exception_id)
        .first()
    )

    if not exception:
        raise HTTPException(status_code=404, detail="Availability exception not found")

    return exception


@router.post("/availability-exceptions", response_model=AvailabilityExceptionResponse)
def create_availability_exception(
    payload: AvailabilityExceptionCreate,
    db: Session = Depends(get_db)
):
    exception = AvailabilityException(
        business_id=payload.business_id,
        specialist_id=payload.specialist_id,
        start_datetime=payload.start_datetime,
        end_datetime=payload.end_datetime,
        reason=payload.reason,
        is_active=True,
    )

    db.add(exception)
    db.commit()
    db.refresh(exception)
    return exception


@router.put("/availability-exceptions/{exception_id}", response_model=AvailabilityExceptionResponse)
def update_availability_exception(
    exception_id: int,
    payload: AvailabilityExceptionUpdate,
    db: Session = Depends(get_db)
):
    exception = (
        db.query(AvailabilityException)
        .filter(AvailabilityException.id == exception_id)
        .first()
    )

    if not exception:
        raise HTTPException(status_code=404, detail="Availability exception not found")

    exception.start_datetime = payload.start_datetime
    exception.end_datetime = payload.end_datetime
    exception.reason = payload.reason
    exception.is_active = payload.is_active

    db.commit()
    db.refresh(exception)
    return exception


@router.put("/availability-exceptions/{exception_id}/disable", response_model=AvailabilityExceptionResponse)
def disable_availability_exception(
    exception_id: int,
    db: Session = Depends(get_db)
):
    exception = (
        db.query(AvailabilityException)
        .filter(AvailabilityException.id == exception_id)
        .first()
    )

    if not exception:
        raise HTTPException(status_code=404, detail="Availability exception not found")

    exception.is_active = False

    db.commit()
    db.refresh(exception)
    return exception