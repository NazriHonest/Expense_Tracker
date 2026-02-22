from fastapi import APIRouter, HTTPException, Depends
from typing import List

from repositories.expense_repository import ExpenseRepository
from schemas.debt_schema import DebtCreate, DebtUpdate, DebtResponse
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/debts", tags=["Debts"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.post("/", response_model=DebtResponse)
async def create_debt(
    debt: DebtCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    res = await repo.create_debt(debt, user_id)
    if not res:
        raise HTTPException(status_code=400, detail="Failed to create debt")
    return res


@router.get("/", response_model=List[DebtResponse])
async def get_debts(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_debts(user_id)


@router.put("/{debt_id}", response_model=DebtResponse)
async def update_debt(
    debt_id: int,
    debt: DebtUpdate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    res = await repo.update_debt(debt_id, debt, user_id)
    if not res:
        raise HTTPException(status_code=404, detail="Debt not found")
    return res


@router.delete("/{debt_id}")
async def delete_debt(
    debt_id: int,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    success = await repo.delete_debt(debt_id, user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Debt not found")
    return {"message": "Debt deleted"}
