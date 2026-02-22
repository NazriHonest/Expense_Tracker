from pydantic import BaseModel
from datetime import datetime
from enum import Enum
from typing import Optional

class SubscriptionFrequency(str, Enum):
    weekly = "weekly"
    monthly = "monthly"
    yearly = "yearly"

class SubscriptionBase(BaseModel):
    title: str
    amount: float
    start_date: datetime
    category: str = "Subscription"
    frequency: SubscriptionFrequency = SubscriptionFrequency.monthly
    is_active: bool = True

class SubscriptionCreate(SubscriptionBase):
    pass

class SubscriptionResponse(SubscriptionBase):
    id: int

    class Config:
        from_attributes = True # Allows compatibility with SQLAlchemy