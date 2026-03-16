from datetime import datetime

from pydantic import BaseModel


class AvailabilityExceptionCreate(BaseModel):
    business_id: int
    specialist_id: int
    start_datetime: datetime
    end_datetime: datetime
    reason: str | None = None

class AvailabilityExceptionUpdate(BaseModel):
    start_datetime: datetime
    end_datetime: datetime
    reason: str | None = None
    is_active: bool

class AvailabilityExceptionResponse(BaseModel):
    id: int
    business_id: int
    specialist_id: int
    start_datetime: datetime
    end_datetime: datetime
    reason: str | None
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True