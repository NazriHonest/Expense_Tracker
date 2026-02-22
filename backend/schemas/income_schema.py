from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class IncomeCreate(BaseModel):
    title: str
    amount: float
    category: str
    date: Optional[datetime] = None
    notes: Optional[str] = None
    wallet_id: Optional[int] = None

class IncomeResponse(BaseModel):
    id: int
    title: str
    amount: float
    category: str
    # Use Optional for the response date to prevent crashes if DB time is null
    date: Optional[datetime] = None 
    notes: Optional[str] = None
    wallet_id: Optional[int] = None

    class Config:
        from_attributes = True