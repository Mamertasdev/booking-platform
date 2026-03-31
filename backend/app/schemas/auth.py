from pydantic import BaseModel


class TokenResponse(BaseModel):
    access_token: str
    token_type: str


class AuthMeResponse(BaseModel):
    id: int
    business_id: int
    username: str
    full_name: str
    role: str
    is_active: bool