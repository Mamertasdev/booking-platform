from datetime import datetime

from pydantic import BaseModel, field_validator


class SpecialistLogin(BaseModel):
    username: str
    password: str

    @field_validator("username")
    @classmethod
    def validate_username(cls, v: str):
        v = v.strip()

        if len(v) < 3:
            raise ValueError("Username too short")

        if len(v) > 50:
            raise ValueError("Username too long")

        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str):
        if len(v) < 4:
            raise ValueError("Password too short")
        return v


class SpecialistCreate(BaseModel):
    business_id: int
    username: str
    password: str
    full_name: str
    role: str = "specialist"

    @field_validator("username")
    @classmethod
    def validate_username(cls, v: str):
        v = v.strip()

        if len(v) < 3:
            raise ValueError("Username too short")

        if len(v) > 50:
            raise ValueError("Username too long")

        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str):
        if len(v) < 4:
            raise ValueError("Password too short")

        if len(v) > 100:
            raise ValueError("Password too long")

        return v

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, v: str):
        v = v.strip()

        if len(v) < 2:
            raise ValueError("Full name too short")

        if len(v) > 100:
            raise ValueError("Full name too long")

        return v

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str):
        v = v.strip().lower()

        if v not in {"admin", "specialist"}:
            raise ValueError("Role must be admin or specialist")

        return v


class SpecialistResponse(BaseModel):
    id: int
    business_id: int
    username: str
    full_name: str
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True