from datetime import datetime

from pydantic import BaseModel

class SpecialistLogin(BaseModel):
    username: str
    password: str

class SpecialistCreate(BaseModel):
    business_id: int
    username: str
    password: str
    full_name: str


class SpecialistResponse(BaseModel):
    id: int
    business_id: int
    username: str
    full_name: str
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True