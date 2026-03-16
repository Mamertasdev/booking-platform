from app.database.database import Base, SessionLocal, engine
from app.models.business import Business
from app.models.specialist import Specialist
from app.models.service import Service
from app.models.appointment import Appointment
from app.models.working_hour import WorkingHour


def init_db():
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        existing_business = db.query(Business).first()

        if not existing_business:
            default_business = Business(
                name="Default Business",
                is_active=True
            )
            db.add(default_business)
            db.commit()
    finally:
        db.close()