from fastapi import APIRouter, HTTPException, Depends
from typing import List

from repositories.expense_repository import ExpenseRepository
from schemas.income_schema import IncomeCreate, IncomeResponse
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/income", tags=["Income"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.post("/", response_model=IncomeResponse)
async def create_income(
    income: IncomeCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.create_income(income, user_id)


@router.get("/", response_model=List[IncomeResponse])
async def read_incomes(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_incomes(user_id)


@router.delete("/{income_id}")
async def delete_income(
    income_id: int,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    deleted = await repo.delete_income(income_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Income not found")
    return {"message": "Income deleted"}


@router.put("/{income_id}", response_model=IncomeResponse)
async def update_income(
    income_id: int,
    income: IncomeCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    updated = await repo.update_income(income_id, income, user_id)
    if not updated:
        raise HTTPException(status_code=404, detail="Income not found")
    return updated
