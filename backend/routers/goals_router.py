from fastapi import APIRouter, HTTPException, Depends
from typing import List
from datetime import datetime

from repositories.expense_repository import ExpenseRepository
from schemas.savings_goal_schema import SavingsGoalCreate, SavingsGoalResponse, ContributionRequest
from schemas.expense_schema import ExpenseCreate, ExpenseResponse
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/goals", tags=["Savings Goals"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.get("/", response_model=List[SavingsGoalResponse])
async def read_goals(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_goals(user_id)


@router.post("/", response_model=SavingsGoalResponse)
async def create_goal(
    goal: SavingsGoalCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.create_goal(goal, user_id)


@router.patch("/{goal_id}/contribute", response_model=SavingsGoalResponse)
async def contribute_to_goal(
    goal_id: str,
    payload: ContributionRequest,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    updated_goal_data = await repo.contribute_to_goal(goal_id, payload.amount, user_id)
    if not updated_goal_data:
        raise HTTPException(status_code=404, detail="Goal not found")

    expense_data = ExpenseCreate(
        title="Savings Contribution",
        amount=payload.amount,
        category="Savings",
        date=datetime.now(),
        notes=f"Contribution to goal ID: {goal_id}",
    )
    await repo.create_expense(expense_data, user_id)
    return updated_goal_data


@router.delete("/{goal_id}")
async def delete_goal(
    goal_id: str,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    deleted = await repo.delete_goal(goal_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Goal not found")
    return {"message": "Goal deleted"}
