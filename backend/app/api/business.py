from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_active_user, require_admin, get_db
from app.models.business import Business
from app.models.specialist import Specialist
from app.schemas.business import BusinessCreate, BusinessResponse, BusinessUpdate

router = APIRouter()


@router.get("/businesses", response_model=list[BusinessResponse])
def get_businesses(
    include_inactive: bool = Query(default=False),
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    query = db.query(Business)

    if current_user.role != "admin":
        query = query.filter(Business.id == current_user.business_id)

    if not include_inactive:
        query = query.filter(Business.is_active == True)

    return query.order_by(Business.name.asc()).all()


@router.get("/businesses/{business_id}", response_model=BusinessResponse)
def get_business(
    business_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    business = (
        db.query(Business)
        .filter(Business.id == business_id)
        .first()
    )

    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    if current_user.role != "admin":
        if business.id != current_user.business_id:
            raise HTTPException(status_code=403, detail="Not allowed")

    return business


@router.post("/businesses", response_model=BusinessResponse)
def create_business(
    payload: BusinessCreate,
    current_user: Specialist = Depends(require_admin),
    db: Session = Depends(get_db)
):
    business = Business(
        name=payload.name.strip(),
        is_active=True,
    )

    db.add(business)
    db.commit()
    db.refresh(business)
    return business


@router.put("/businesses/{business_id}", response_model=BusinessResponse)
def update_business(
    business_id: int,
    payload: BusinessUpdate,
    current_user: Specialist = Depends(require_admin),
    db: Session = Depends(get_db)
):
    business = (
        db.query(Business)
        .filter(Business.id == business_id)
        .first()
    )

    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    business.name = payload.name.strip()
    business.is_active = payload.is_active

    db.commit()
    db.refresh(business)
    return business


@router.put("/businesses/{business_id}/disable", response_model=BusinessResponse)
def disable_business(
    business_id: int,
    current_user: Specialist = Depends(require_admin),
    db: Session = Depends(get_db)
):
    business = (
        db.query(Business)
        .filter(Business.id == business_id)
        .first()
    )

    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    business.is_active = False

    db.commit()
    db.refresh(business)
    return business