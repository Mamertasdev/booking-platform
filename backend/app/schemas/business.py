from datetime import datetime

from pydantic import BaseModel, field_validator


class BusinessCreate(BaseModel):
    name: str

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str):
        v = v.strip()

        if len(v) < 2:
            raise ValueError("Business name too short")

        if len(v) > 100:
            raise ValueError("Business name too long")

        return v


class BusinessUpdate(BaseModel):
    name: str
    is_active: bool

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str):
        v = v.strip()

        if len(v) < 2:
            raise ValueError("Business name too short")

        if len(v) > 100:
            raise ValueError("Business name too long")

        return v


class BusinessResponse(BaseModel):
    id: int
    name: str
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True