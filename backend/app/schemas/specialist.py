from datetime import datetime
from typing import Optional

from pydantic import BaseModel, field_validator


ALLOWED_ROLES = {"admin", "owner", "specialist"}


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
    business_id: Optional[int] = None
    username: str
    password: str
    full_name: str
    role: str = "specialist"
    is_bookable: bool = True

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

        if v not in ALLOWED_ROLES:
            raise ValueError("Role must be admin, owner or specialist")

        return v


class SpecialistUpdate(BaseModel):
    business_id: Optional[int] = None
    username: str
    password: str | None = None
    full_name: str
    role: str
    is_active: bool
    is_bookable: bool = True

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
    def validate_password(cls, v: str | None):
        if v is None:
            return v

        v = v.strip()

        if not v:
            return None

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

        if v not in ALLOWED_ROLES:
            raise ValueError("Role must be admin, owner or specialist")

        return v


class SpecialistResponse(BaseModel):
    id: int
    business_id: Optional[int] = None
    username: str
    full_name: str
    role: str
    is_active: bool
    is_bookable: bool
    created_at: datetime

    class Config:
        from_attributes = True