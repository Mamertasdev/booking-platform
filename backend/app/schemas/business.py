from datetime import datetime

from pydantic import BaseModel


class BusinessCreate(BaseModel):
    name: str


class BusinessResponse(BaseModel):
    id: int
    name: str
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True