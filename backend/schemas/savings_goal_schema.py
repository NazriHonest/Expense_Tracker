from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class SavingsGoalCreate(BaseModel):
    title: str
    target_amount: float
    current_amount: Optional[float] = 0.0
    category: str
    target_date: datetime
    color_value: int

class SavingsGoalResponse(SavingsGoalCreate):
    id: int

class ContributionRequest(BaseModel):
    amount: float