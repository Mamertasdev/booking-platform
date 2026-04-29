from datetime import datetime

from pydantic import BaseModel


class AppointmentCreate(BaseModel):
    business_id: int
    specialist_id: int
    service_id: int
    client_full_name: str
    client_email: str
    client_phone: str | None = None
    notes: str | None = None
    appointment_start: datetime


class AppointmentUpdateStatus(BaseModel):
    status: str


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
    status: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True