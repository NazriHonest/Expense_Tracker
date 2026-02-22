from fastapi import APIRouter, HTTPException, Depends
from typing import List

from repositories.expense_repository import ExpenseRepository
from schemas.expense_schema import ExpenseCreate, ExpenseResponse, MonthlySummary
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/expenses", tags=["Expenses"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.post("/", response_model=ExpenseResponse)
async def create_expense(
    expense: ExpenseCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.create_expense(expense, user_id)


@router.get("/", response_model=List[ExpenseResponse])
async def read_expenses(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_expenses(user_id)


@router.get("/summary", response_model=List[MonthlySummary])
async def get_summary(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_monthly_summary(user_id)


@router.delete("/{expense_id}")
async def delete_expense(
    expense_id: int,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    deleted = await repo.delete_expense(expense_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Expense not found")
    return {"message": "Expense deleted"}


@router.put("/{expense_id}", response_model=ExpenseResponse)
async def update_expense(
    expense_id: int,
    expense: ExpenseCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    updated = await repo.update_expense(expense_id, expense, user_id)
    if not updated:
        raise HTTPException(status_code=404, detail="Expense not found")
    return updated
