from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.specialist import Specialist

router = APIRouter()


@router.get("/specialists")
def get_public_specialists(db: Session = Depends(get_db)):
    specialists = (
        db.query(Specialist)
        .filter(Specialist.is_active == True)
        .all()
    )

    return [
        {
            "id": specialist.id,
            "full_name": specialist.full_name,
        }
        for specialist in specialists
    ]