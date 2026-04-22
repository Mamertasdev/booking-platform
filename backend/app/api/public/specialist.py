from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.specialist import Specialist

router = APIRouter()


@router.get("/specialists")
def get_public_specialists(
    business_id: int = Query(...),
    db: Session = Depends(get_db),
):
    specialists = (
        db.query(Specialist)
        .filter(Specialist.business_id == business_id)
        .filter(Specialist.role.in_(["owner", "specialist"]))
        .filter(Specialist.is_active == True)
        .order_by(Specialist.full_name.asc())
        .all()
    )

    if not specialists:
        return []

    return [
        {
            "id": specialist.id,
            "full_name": specialist.full_name,
        }
        for specialist in specialists
    ]