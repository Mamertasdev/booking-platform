from datetime import time

from pydantic import BaseModel


class WorkingHourCreate(BaseModel):
    business_id: int
    specialist_id: int
    weekday: int
    start_time: time
    end_time: time

class WorkingHourUpdate(BaseModel):
    weekday: int
    start_time: time
    end_time: time
    is_active: bool

class WorkingHourResponse(BaseModel):
    id: int
    business_id: int
    specialist_id: int
    weekday: int
    start_time: time
    end_time: time
    is_active: bool

    class Config:
        orm_mode = True