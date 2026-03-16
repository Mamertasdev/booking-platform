from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Time

from app.database.base import Base


class WorkingHour(Base):
    __tablename__ = "working_hours"

    id = Column(Integer, primary_key=True, index=True)

    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=False, index=True)
    specialist_id = Column(Integer, ForeignKey("specialists.id"), nullable=False, index=True)

    weekday = Column(Integer, nullable=False)  # 0 = Monday, 6 = Sunday
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)

    is_active = Column(Boolean, default=True, nullable=False)