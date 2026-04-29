from datetime import datetime

from pydantic import BaseModel, field_validator


class AvailabilityExceptionCreate(BaseModel):
    business_id: int
    specialist_id: int
    start_datetime: datetime
    end_datetime: datetime
    reason: str | None = None

    @field_validator("end_datetime")
    @classmethod
    def validate_datetime_range(cls, v: datetime, info):
        start_datetime = info.data.get("start_datetime")
        if start_datetime and v <= start_datetime:
            raise ValueError("End datetime must be later than start datetime")
        return v

    @field_validator("reason")
    @classmethod
    def validate_reason(cls, v: str | None):
        if not v:
            return v

        v = v.strip()

        if len(v) > 200:
            raise ValueError("Reason too long")

        return v


class AvailabilityExceptionUpdate(BaseModel):
    start_datetime: datetime
    end_datetime: datetime
    reason: str | None = None
    is_active: bool

    @field_validator("end_datetime")
    @classmethod
    def validate_datetime_range(cls, v: datetime, info):
        start_datetime = info.data.get("start_datetime")
        if start_datetime and v <= start_datetime:
            raise ValueError("End datetime must be later than start datetime")
        return v

    @field_validator("reason")
    @classmethod
    def validate_reason(cls, v: str | None):
        if not v:
            return v

        v = v.strip()

        if len(v) > 200:
            raise ValueError("Reason too long")

        return v


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
        from_attributes = True