from datetime import datetime

from pydantic import BaseModel


class ServiceCreate(BaseModel):
    business_id: int
    name: str
    duration_minutes: int
    price: int


class ServiceResponse(BaseModel):
    id: int
    business_id: int
    name: str
    duration_minutes: int
    price: int
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True