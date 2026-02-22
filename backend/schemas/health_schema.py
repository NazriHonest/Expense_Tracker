from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime

class HealthMetricsBase(BaseModel):
    date: date
    water_intake: int = 0
    steps: int = 0
    sleep_hours: float = 0.0
    mood: Optional[str] = None
    calories_burned: int = 0
    active_minutes: int = 0

class HealthMetricsCreate(HealthMetricsBase):
    pass

class HealthMetricsResponse(HealthMetricsBase):
    id: int
    user_id: int
    created_at: datetime

class HealthSettingsBase(BaseModel):
    water_goal: int = 2500
    steps_goal: int = 10000
    sleep_goal: float = 8.0
    reminder_interval: int = 60
    break_interval: int = 60
    exercise_reminder: bool = True

class HealthSettingsUpdate(HealthSettingsBase):
    pass

class HealthSettingsResponse(HealthSettingsBase):
    id: int
    user_id: int
    created_at: datetime
