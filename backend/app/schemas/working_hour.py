from datetime import time

from pydantic import BaseModel, field_validator


class WorkingHourCreate(BaseModel):
    business_id: int
    specialist_id: int
    weekday: int
    start_time: time
    end_time: time

    @field_validator("weekday")
    @classmethod
    def validate_weekday(cls, v: int):
        if v < 0 or v > 6:
            raise ValueError("Weekday must be between 0 and 6")
        return v

    @field_validator("end_time")
    @classmethod
    def validate_time_range(cls, v: time, info):
        start_time = info.data.get("start_time")
        if start_time and v <= start_time:
            raise ValueError("End time must be later than start time")
        return v


class WorkingHourUpdate(BaseModel):
    weekday: int
    start_time: time
    end_time: time
    is_active: bool

    @field_validator("weekday")
    @classmethod
    def validate_weekday(cls, v: int):
        if v < 0 or v > 6:
            raise ValueError("Weekday must be between 0 and 6")
        return v

    @field_validator("end_time")
    @classmethod
    def validate_time_range(cls, v: time, info):
        start_time = info.data.get("start_time")
        if start_time and v <= start_time:
            raise ValueError("End time must be later than start time")
        return v


class WorkingHourResponse(BaseModel):
    id: int
    business_id: int
    specialist_id: int
    weekday: int
    start_time: time
    end_time: time
    is_active: bool

    class Config:
        from_attributes = True