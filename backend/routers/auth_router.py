from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta

from repositories.expense_repository import ExpenseRepository
from schemas.user_schema import UserCreate, UserResponse, Token
from auth import get_password_hash, verify_password, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/auth", tags=["Auth"])


def get_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)


@router.post("/register", response_model=UserResponse)
async def register(user: UserCreate, repo: ExpenseRepository = Depends(get_repository)):
    try:
        db_user = await repo.get_user_by_email(user.email)
        if db_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        hashed_password = get_password_hash(user.password)
        new_user = await repo.create_user(user, hashed_password)
        return new_user
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/token", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    repo: ExpenseRepository = Depends(get_repository),
):
    user = await repo.get_user_by_email(form_data.username)
    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user["id"]), "email": user["email"]},
        expires_delta=access_token_expires,
    )
    return {"access_token": access_token, "token_type": "bearer"}
