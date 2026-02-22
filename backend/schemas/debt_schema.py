from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class DebtBase(BaseModel):
    title: str
    amount: float
    due_date: Optional[datetime] = None
    is_owed_by_me: bool = True
    status: str = 'pending'
    notes: Optional[str] = None

class DebtCreate(DebtBase):
    pass

class DebtUpdate(DebtBase):
    title: Optional[str] = None
    amount: Optional[float] = None
    is_owed_by_me: Optional[bool] = None
    status: Optional[str] = None
    wallet_id: Optional[int] = None

class DebtResponse(DebtBase):
    id: int

    class Config:
        from_attributes = True
