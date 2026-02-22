from pydantic import BaseModel
from typing import Optional

class CategoryBase(BaseModel):
    name: str
    icon_code: int
    color_value: int
    type: str = 'expense' # 'expense' or 'income'

class CategoryCreate(CategoryBase):
    pass

class CategoryResponse(CategoryBase):
    id: int

    class Config:
        from_attributes = True
