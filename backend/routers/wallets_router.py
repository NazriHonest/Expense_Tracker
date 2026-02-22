from fastapi import APIRouter, HTTPException, Depends
from typing import List

from repositories.expense_repository import ExpenseRepository
from schemas.wallet_schema import WalletCreate, WalletUpdate, WalletResponse
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/wallets", tags=["Wallets"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.post("/", response_model=WalletResponse)
async def create_wallet(
    wallet: WalletCreate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    res = await repo.create_wallet(
        name=wallet.name,
        icon_code=wallet.icon_code,
        color_value=wallet.color_value,
        balance=wallet.balance,
        is_default=wallet.is_default,
        user_id=user_id,
    )
    if not res:
        raise HTTPException(status_code=400, detail="Failed to create wallet")
    return res


@router.get("/", response_model=List[WalletResponse])
async def get_wallets(
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_wallets(user_id)


@router.put("/{wallet_id}", response_model=WalletResponse)
async def update_wallet(
    wallet_id: int,
    wallet: WalletUpdate,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    res = await repo.update_wallet(wallet_id, wallet.model_dump(exclude_unset=True), user_id)
    if not res:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return res


@router.delete("/{wallet_id}")
async def delete_wallet(
    wallet_id: int,
    repo: ExpenseRepository = Depends(get_repository),
    user_id: int = Depends(get_current_user_id),
):
    deleted = await repo.delete_wallet(wallet_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return {"message": "Wallet deleted"}
