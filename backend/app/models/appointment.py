from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.sql import func

from app.database.base import Base


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)

    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=False, index=True)
    specialist_id = Column(Integer, ForeignKey("specialists.id"), nullable=False, index=True)
    service_id = Column(Integer, ForeignKey("services.id"), nullable=False, index=True)

    client_full_name = Column(String, nullable=False)
    client_email = Column(String, nullable=False)
    client_phone = Column(String, nullable=True)
    notes = Column(String, nullable=True)

    appointment_start = Column(DateTime(timezone=True), nullable=False)
    appointment_end = Column(DateTime(timezone=True), nullable=False)

    status = Column(String, nullable=False, default="confirmed")
    is_active = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)