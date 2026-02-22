from fastapi import APIRouter, HTTPException, Depends
from typing import List

from repositories.expense_repository import ExpenseRepository
from schemas.category_schema import CategoryCreate, CategoryResponse
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/categories", tags=["Categories"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.get("/", response_model=List[CategoryResponse])
async def get_categories(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_categories(user_id)


@router.post("/", response_model=CategoryResponse)
async def create_category(
    category: CategoryCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    new_cat = await repo.create_category(
        user_id, category.name, category.icon_code, category.color_value, category.type
    )
    if not new_cat:
        raise HTTPException(status_code=400, detail="Category already exists")
    return new_cat


@router.delete("/{category_id}")
async def delete_category(
    category_id: int,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    success = await repo.delete_category(category_id, user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Category not found or not authorized")
    return {"message": "Category deleted"}
