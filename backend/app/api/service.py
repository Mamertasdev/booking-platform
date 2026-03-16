from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.service import Service
from app.schemas.service import ServiceCreate, ServiceResponse, ServiceUpdate

router = APIRouter()


@router.get("/services", response_model=list[ServiceResponse])
def get_services(
    business_id: int | None = Query(default=None),
    is_active: bool | None = Query(default=None),
    db: Session = Depends(get_db)
):
    query = db.query(Service)

    if business_id is not None:
        query = query.filter(Service.business_id == business_id)

    if is_active is not None:
        query = query.filter(Service.is_active == is_active)

    return query.all()


@router.get("/services/{service_id}", response_model=ServiceResponse)
def get_service(service_id: int, db: Session = Depends(get_db)):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    return service


@router.post("/services", response_model=ServiceResponse)
def create_service(payload: ServiceCreate, db: Session = Depends(get_db)):
    service = Service(
        business_id=payload.business_id,
        name=payload.name,
        duration_minutes=payload.duration_minutes,
        price=payload.price,
        is_active=True,
    )
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


@router.put("/services/{service_id}", response_model=ServiceResponse)
def update_service(
    service_id: int,
    payload: ServiceUpdate,
    db: Session = Depends(get_db)
):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    service.name = payload.name
    service.duration_minutes = payload.duration_minutes
    service.price = payload.price
    service.is_active = payload.is_active

    db.commit()
    db.refresh(service)
    return service