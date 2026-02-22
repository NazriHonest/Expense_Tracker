from pydantic import BaseModel
from typing import Optional

class BudgetBase(BaseModel):
    category: str
    amount: float
    month: int
    year: int

class BudgetCreate(BudgetBase):
    pass    

class BudgetResponse(BudgetBase):
    id: int
    user_id: int