import os

from app.core.security import hash_password
from app.database.database import SessionLocal
from app.models.business import Business
from app.models.specialist import Specialist


def _get_required_env(name: str) -> str:
    value = os.getenv(name)
    if value is None or not value.strip():
        raise ValueError(f"Missing required environment variable: {name}")
    return value.strip()


def bootstrap_admin():
    admin_username = _get_required_env("BOOTSTRAP_ADMIN_USERNAME")
    admin_password = _get_required_env("BOOTSTRAP_ADMIN_PASSWORD")
    admin_full_name = _get_required_env("BOOTSTRAP_ADMIN_FULL_NAME")

    db = SessionLocal()
    try:
        existing_admin = (
            db.query(Specialist)
            .filter(Specialist.username == admin_username)
            .first()
        )

        if existing_admin:
            print("Admin user already exists. Nothing to do.")
            return

        admin_user = Specialist(
            business_id=None,
            username=admin_username,
            password_hash=hash_password(admin_password),
            full_name=admin_full_name,
            role="admin",
            is_active=True,
        )
        db.add(admin_user)
        db.commit()

        print("Admin user created successfully.")
        print(f"Username: {admin_username}")
    finally:
        db.close()


if __name__ == "__main__":
    bootstrap_admin()