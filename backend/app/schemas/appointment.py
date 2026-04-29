from datetime import datetime
from enum import Enum

from pydantic import BaseModel, EmailStr, field_validator


class AppointmentStatus(str, Enum):
    pending = "pending"
    confirmed = "confirmed"
    completed = "completed"
    cancelled_by_client = "cancelled_by_client"
    cancelled_by_admin = "cancelled_by_admin"
    no_show = "no_show"


class AppointmentCreate(BaseModel):
    business_id: int
    specialist_id: int
    service_id: int
    client_full_name: str
    client_email: EmailStr
    client_phone: str | None = None
    notes: str | None = None
    appointment_start: datetime

    @field_validator("client_full_name")
    @classmethod
    def validate_name(cls, v: str):
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Name too short")
        if len(v) > 100:
            raise ValueError("Name too long")
        return v

    @field_validator("client_phone")
    @classmethod
    def validate_phone(cls, v: str | None):
        if not v:
            return v

        v = v.strip()

        if len(v) < 8 or len(v) > 20:
            raise ValueError("Invalid phone number length")

        if not all(c.isdigit() or c in "+-() " for c in v):
            raise ValueError("Invalid phone number format")

        return v

    @field_validator("notes")
    @classmethod
    def validate_notes(cls, v: str | None):
        if not v:
            return v

        if len(v) > 500:
            raise ValueError("Notes too long")

        return v

    @field_validator("appointment_start")
    @classmethod
    def validate_appointment_start(cls, v: datetime):
        now = datetime.now()
        if v < now:
            raise ValueError("Appointment time cannot be in the past")
        return v


class AppointmentUpdateStatus(BaseModel):
    status: AppointmentStatus


class AppointmentReschedule(BaseModel):
    appointment_start: datetime

    @field_validator("appointment_start")
    @classmethod
    def validate_appointment_start(cls, v: datetime):
        now = datetime.now()
        if v < now:
            raise ValueError("Appointment time cannot be in the past")
        return v


class AppointmentResponse(BaseModel):
    id: int
    business_id: int
    specialist_id: int
    service_id: int
    client_full_name: str
    client_email: str
    client_phone: str | None
    notes: str | None
    appointment_start: datetime
    appointment_end: datetime
    status: AppointmentStatus
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True