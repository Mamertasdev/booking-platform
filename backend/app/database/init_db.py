from app.core.security import hash_password
from app.database.database import Base, SessionLocal, engine
from app.models.appointment import Appointment
from app.models.availability_exception import AvailabilityException
from app.models.business import Business
from app.models.service import Service
from app.models.specialist import Specialist
from app.models.working_hour import WorkingHour


def init_db():
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        existing_business = db.query(Business).first()

        if not existing_business:
            default_business = Business(
                name="Default Business",
                is_active=True,
            )
            db.add(default_business)
            db.commit()
            db.refresh(default_business)
            business_id = default_business.id
        else:
            business_id = existing_business.id

        existing_admin = (
            db.query(Specialist)
            .filter(Specialist.username == "Admin")
            .first()
        )

        if not existing_admin:
            admin_user = Specialist(
                business_id=business_id,
                username="Admin",
                password_hash=hash_password("Admin1"),
                full_name="System Admin",
                role="admin",
                is_active=True,
            )
            db.add(admin_user)
            db.commit()
    finally:
        db.close()