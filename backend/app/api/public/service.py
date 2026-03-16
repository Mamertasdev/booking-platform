from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.service import Service

router = APIRouter()


@router.get("/services")
def get_public_services(
    business_id: int = Query(...),
    db: Session = Depends(get_db),
):
    services = (
        db.query(Service)
        .filter(Service.business_id == business_id)
        .filter(Service.is_active == True)
        .all()
    )

    return [
        {
            "id": service.id,
            "name": service.name,
            "duration_minutes": service.duration_minutes,
            "price": service.price,
        }
        for service in services
    ]