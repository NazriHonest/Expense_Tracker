from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class WalletBase(BaseModel):
    name: str
    icon_code: Optional[int] = 57544 # Default generic icon
    color_value: Optional[int] = 4280391411 # Default color
    balance: Optional[float] = 0.0
    is_default: Optional[bool] = False

class WalletCreate(WalletBase):
    pass

class WalletUpdate(BaseModel):
    name: Optional[str] = None
    icon_code: Optional[int] = None
    color_value: Optional[int] = None
    balance: Optional[float] = None
    is_default: Optional[bool] = None

class WalletResponse(WalletBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
