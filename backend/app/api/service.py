from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_active_user, get_db
from app.models.service import Service
from app.models.specialist import Specialist
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
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    query = db.query(Service)

    if current_user.role != "admin":
        business_id = current_user.business_id

    if business_id is not None:
        query = query.filter(Service.business_id == business_id)

    if not include_inactive:
        query = query.filter(Service.is_active == True)

    return query.order_by(Service.name.asc()).all()


@router.get("/services/{service_id}", response_model=ServiceResponse)
def get_service(
    service_id: int,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    if current_user.role != "admin" and service.business_id != current_user.business_id:
        raise HTTPException(status_code=403, detail="Not allowed")

    return service


@router.post("/services", response_model=ServiceResponse)
def create_service(
    payload: ServiceCreate,
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    business_id = payload.business_id

    if current_user.role != "admin":
        business_id = current_user.business_id

    ensure_unique_active_service_name(
        db=db,
        business_id=business_id,
        service_name=payload.name,
    )

    service = Service(
        business_id=business_id,
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
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    if current_user.role != "admin" and service.business_id != current_user.business_id:
        raise HTTPException(status_code=403, detail="Not allowed")

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
    current_user: Specialist = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    if current_user.role != "admin" and service.business_id != current_user.business_id:
        raise HTTPException(status_code=403, detail="Not allowed")

    service.is_active = False

    db.commit()
    db.refresh(service)
    return service