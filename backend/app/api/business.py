from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.business import Business
from app.schemas.business import BusinessCreate, BusinessResponse

router = APIRouter()


@router.get("/businesses", response_model=list[BusinessResponse])
def get_businesses(db: Session = Depends(get_db)):
    return db.query(Business).all()


@router.post("/businesses", response_model=BusinessResponse)
def create_business(payload: BusinessCreate, db: Session = Depends(get_db)):
    business = Business(
        name=payload.name,
        is_active=True
    )
    db.add(business)
    db.commit()
    db.refresh(business)
    return business