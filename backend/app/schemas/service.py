from datetime import datetime

from pydantic import BaseModel, field_validator


class ServiceCreate(BaseModel):
    business_id: int | None = None
    name: str
    duration_minutes: int
    price: int

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str):
        v = v.strip()

        if len(v) < 2:
            raise ValueError("Service name too short")

        if len(v) > 100:
            raise ValueError("Service name too long")

        return v

    @field_validator("duration_minutes")
    @classmethod
    def validate_duration_minutes(cls, v: int):
        if v <= 0:
            raise ValueError("Duration must be greater than 0")
        if v > 1440:
            raise ValueError("Duration is too large")
        return v

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: int):
        if v < 0:
            raise ValueError("Price cannot be negative")
        return v


class ServiceUpdate(BaseModel):
    name: str
    duration_minutes: int
    price: int
    is_active: bool

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str):
        v = v.strip()

        if len(v) < 2:
            raise ValueError("Service name too short")

        if len(v) > 100:
            raise ValueError("Service name too long")

        return v

    @field_validator("duration_minutes")
    @classmethod
    def validate_duration_minutes(cls, v: int):
        if v <= 0:
            raise ValueError("Duration must be greater than 0")
        if v > 1440:
            raise ValueError("Duration is too large")
        return v

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: int):
        if v < 0:
            raise ValueError("Price cannot be negative")
        return v


class ServiceResponse(BaseModel):
    id: int
    business_id: int
    name: str
    duration_minutes: int
    price: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True