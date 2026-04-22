from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import (
    ROLE_ADMIN,
    ROLE_OWNER,
    ROLE_SPECIALIST,
    get_current_active_user,
    get_db,
)
from app.models.working_hour import WorkingHour
from app.models.specialist import Specialist
from app.schemas.working_hour import (
    WorkingHourCreate,
    WorkingHourResponse,
    WorkingHourUpdate,
)

router = APIRouter()


def _require_user_business_id(user: Specialist) -> int:
    if user.business_id is None:
        raise HTTPException(
            status_code=400,
            detail="User has no business assigned",
        )
    return user.business_id


def _normalize_scope(
    *,
    business_id: int | None,
    specialist_id: int | None,
    current_user: Specialist,
) -> tuple[int | None, int | None]:
    if current_user.role == ROLE_ADMIN:
        return business_id, specialist_id

    if current_user.role == ROLE_OWNER:
        return _require_user_business_id(current_user), specialist_id

    if current_user.role == ROLE_SPECIALIST:
        return _require_user_business_id(current_user), current_user.id

    raise HTTPException(status_code=403, detail="Not allowed")


def _ensure_access(
    current_user: Specialist,
    item: WorkingHour,
):
    if current_user.role == ROLE_ADMIN:
        return

    if current_user.role == ROLE_OWNER:
        if item.business_id != _require_user_business_id(current_user):
            raise HTTPException(status_code=403, detail="Not allowed")
        return

    if current_user.role == ROLE_SPECIALIST:
        if (
            item.business_id != _require_user_business_id(current_user)
            or item.specialist_id != current_user.id
        ):
            raise HTTPException(status_code=403, detail="Not allowed")
        return

    raise HTTPException(status_code=403, detail="Not allowed")


@router.get("/working-hours", response_model=list[WorkingHourResponse])
def get_working_hours(
    include_inactive: bool = False,
    business_id: int | None = None,
    specialist_id: int | None = None,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    business_id, specialist_id = _normalize_scope(
        business_id=business_id,
        specialist_id=specialist_id,
        current_user=current_user,
    )

    query = db.query(WorkingHour)

    if not include_inactive:
        query = query.filter(WorkingHour.is_active == True)

    if business_id is not None:
        query = query.filter(WorkingHour.business_id == business_id)

    if specialist_id is not None:
        query = query.filter(WorkingHour.specialist_id == specialist_id)

    return query.order_by(WorkingHour.weekday.asc()).all()


@router.post("/working-hours", response_model=WorkingHourResponse)
def create_working_hour(
    payload: WorkingHourCreate,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    business_id, specialist_id = _normalize_scope(
        business_id=payload.business_id,
        specialist_id=payload.specialist_id,
        current_user=current_user,
    )

    if business_id is None or specialist_id is None:
        raise HTTPException(status_code=400, detail="Invalid scope")

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
    db: Session = Depends(get_db),
):
    item = (
        db.query(WorkingHour)
        .filter(WorkingHour.id == working_hour_id)
        .first()
    )

    if not item:
        raise HTTPException(status_code=404, detail="Working hour not found")

    _ensure_access(current_user, item)

    item.weekday = payload.weekday
    item.start_time = payload.start_time
    item.end_time = payload.end_time
    item.is_active = payload.is_active

    db.commit()
    db.refresh(item)
    return item


@router.put("/working-hours/{working_hour_id}/disable", response_model=WorkingHourResponse)
def disable_working_hour(
    working_hour_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    item = (
        db.query(WorkingHour)
        .filter(WorkingHour.id == working_hour_id)
        .first()
    )

    if not item:
        raise HTTPException(status_code=404, detail="Working hour not found")

    _ensure_access(current_user, item)

    item.is_active = False

    db.commit()
    db.refresh(item)
    return item