from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional
from datetime import datetime

from repositories.expense_repository import ExpenseRepository
from schemas.budget_schema import BudgetCreate, BudgetResponse
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/budgets", tags=["Budgets"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.post("/", response_model=dict)
async def set_budget(
    budget: BudgetCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    result = await repo.set_budget(
        user_id=user_id,
        category=budget.category,
        amount=budget.amount,
        month=budget.month,
        year=budget.year,
    )
    return {"message": "Budget saved successfully", "budget": result}


@router.get("/status", response_model=List[dict])
async def get_budget_status(
    month: Optional[int] = None,
    year: Optional[int] = None,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    now = datetime.now()
    target_month = month or now.month
    target_year = year or now.year
    return await repo.get_budget_status(user_id, target_month, target_year)


@router.delete("/{budget_id}")
async def delete_budget(
    budget_id: int,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    deleted = await repo.delete_budget(budget_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Budget not found")
    return {"message": "Budget deleted"}
