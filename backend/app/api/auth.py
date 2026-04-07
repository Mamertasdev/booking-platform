from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_active_user, get_db
from app.core.security import create_access_token, verify_password
from app.models.specialist import Specialist
from app.schemas.auth import AuthMeResponse, TokenResponse
from app.schemas.specialist import SpecialistLogin

router = APIRouter()


@router.post("/auth/login", response_model=TokenResponse)
def login(payload: SpecialistLogin, db: Session = Depends(get_db)):
    normalized_username = payload.username.strip()
    print("LOGIN ATTEMPT:", repr(normalized_username))

    user = (
        db.query(Specialist)
        .filter(Specialist.username == normalized_username)
        .first()
    )

    print("USER FOUND:", user is not None)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
        )

    print("USER ACTIVE:", user.is_active)

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user",
        )

    password_ok = verify_password(payload.password, user.password_hash)
    print("PASSWORD OK:", password_ok)

    if not password_ok:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
        )

    access_token = create_access_token(
        {
            "sub": str(user.id),
            "role": user.role,
            "business_id": user.business_id,
        }
    )

    print("LOGIN SUCCESS FOR USER ID:", user.id)

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }


@router.get("/auth/me", response_model=AuthMeResponse)
def get_me(current_user: Specialist = Depends(get_current_active_user)):
    return {
        "id": current_user.id,
        "business_id": current_user.business_id,
        "username": current_user.username,
        "full_name": current_user.full_name,
        "role": current_user.role,
        "is_active": current_user.is_active,
    }