from fastapi import APIRouter, Depends

from repositories.expense_repository import ExpenseRepository
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/analytics", tags=["Analytics"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.get("/category-breakdown")
async def get_category_breakdown(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_category_breakdown(user_id)


@router.get("/monthly-comparison")
async def get_monthly_comparison(
    months: int = 6,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_monthly_comparison(user_id, months)


@router.get("/insights")
async def get_insights(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_insights(user_id)


@router.get("/export")
async def export_data(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_export_data(user_id)


@router.get("/balance")
async def get_balance(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_balance_summary(user_id)
