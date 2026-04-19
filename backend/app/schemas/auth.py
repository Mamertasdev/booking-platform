from typing import Optional

from pydantic import BaseModel


class TokenResponse(BaseModel):
    access_token: str
    token_type: str


class AuthMeResponse(BaseModel):
    id: int
    business_id: Optional[int] = None
    username: str
    full_name: str
    role: str
    is_active: bool