from fastapi import APIRouter, HTTPException, Depends
from typing import List

from repositories.expense_repository import ExpenseRepository
from schemas.subscription_schema import SubscriptionCreate, SubscriptionResponse
from schemas.expense_schema import ExpenseResponse
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/subscriptions", tags=["Subscriptions"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.get("/", response_model=List[SubscriptionResponse])
async def get_subscriptions(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_subscriptions(user_id)


@router.post("/", response_model=SubscriptionResponse)
async def create_subscription(
    subscription: SubscriptionCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.create_subscription(subscription, user_id)


@router.put("/{sub_id}", response_model=SubscriptionResponse)
async def update_subscription(
    sub_id: int,
    subscription: SubscriptionCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    updated = await repo.update_subscription(sub_id, subscription, user_id)
    if not updated:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return updated


@router.delete("/{sub_id}")
async def delete_subscription(
    sub_id: int,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    deleted = await repo.delete_subscription(sub_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return {"message": "Subscription deleted"}


@router.post("/check", response_model=List[ExpenseResponse])
async def check_subscriptions(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.check_recurring_transactions(user_id)
