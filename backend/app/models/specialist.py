from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.sql import func

from app.database.base import Base


class Specialist(Base):
    __tablename__ = "specialists"

    id = Column(Integer, primary_key=True, index=True)

    # 🔑 Dabar nullable – admin gali neturėti business
    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=True, index=True)

    username = Column(String, nullable=False, unique=True, index=True)
    password_hash = Column(String, nullable=False)
    full_name = Column(String, nullable=False)

    # 🔑 Paliekam role, bet leisim "admin", "owner", "specialist"
    role = Column(String, nullable=False, default="specialist")

    is_active = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)