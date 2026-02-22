from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ExpenseBase(BaseModel):
    title: str
    amount: float
    category: str
    date: Optional[datetime] = None
    notes: Optional[str] = None
    wallet_id: Optional[int] = None

class ExpenseCreate(ExpenseBase):
    pass

class ExpenseResponse(ExpenseBase):
    id: int

    class Config:
        from_attributes = True

class MonthlySummary(BaseModel):
    month: str
    total_amount: float


