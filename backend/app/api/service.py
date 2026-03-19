from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.service import Service
from app.schemas.service import ServiceCreate, ServiceResponse, ServiceUpdate

router = APIRouter()


def normalize_service_name(value: str) -> str:
    return value.strip().lower()


def ensure_unique_active_service_name(
    db: Session,
    business_id: int,
    service_name: str,
    exclude_id: int | None = None,
):
    normalized_name = normalize_service_name(service_name)

    query = (
        db.query(Service)
        .filter(Service.business_id == business_id)
        .filter(Service.is_active == True)
    )

    if exclude_id is not None:
        query = query.filter(Service.id != exclude_id)

    existing_services = query.all()

    for service in existing_services:
        if normalize_service_name(service.name) == normalized_name:
            raise HTTPException(
                status_code=400,
                detail="An active service with this name already exists",
            )


@router.get("/services", response_model=list[ServiceResponse])
def get_services(
    business_id: int | None = Query(default=None),
    include_inactive: bool = Query(default=False),
    db: Session = Depends(get_db)
):
    query = db.query(Service)

    if business_id is not None:
        query = query.filter(Service.business_id == business_id)

    if not include_inactive:
        query = query.filter(Service.is_active == True)

    return query.order_by(Service.name.asc()).all()


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
    ensure_unique_active_service_name(
        db=db,
        business_id=payload.business_id,
        service_name=payload.name,
    )

    service = Service(
        business_id=payload.business_id,
        name=payload.name.strip(),
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

    if payload.is_active:
        ensure_unique_active_service_name(
            db=db,
            business_id=service.business_id,
            service_name=payload.name,
            exclude_id=service.id,
        )

    service.name = payload.name.strip()
    service.duration_minutes = payload.duration_minutes
    service.price = payload.price
    service.is_active = payload.is_active

    db.commit()
    db.refresh(service)
    return service


@router.put("/services/{service_id}/disable", response_model=ServiceResponse)
def disable_service(
    service_id: int,
    db: Session = Depends(get_db)
):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    service.is_active = False

    db.commit()
    db.refresh(service)
    return service