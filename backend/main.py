import os
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from database import Database, get_db_pool

# Import all routers
from routers.auth_router import router as auth_router
from routers.expenses_router import router as expenses_router
from routers.income_router import router as income_router
from routers.budget_router import router as budget_router
from routers.goals_router import router as goals_router
from routers.subscriptions_router import router as subscriptions_router
from routers.wallets_router import router as wallets_router
from routers.debts_router import router as debts_router
from routers.categories_router import router as categories_router
from routers.health_router import router as health_router
from routers.analytics_router import router as analytics_router

app = FastAPI(
    title="Expense Tracker API",
    description="Backend for Flutter Expense Tracker",
    version="2.0.0",
)

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    await Database.connect()
    pool = await get_db_pool()
    with open(os.path.join(os.path.dirname(__file__), "schema.sql"), "r") as f:
        schema_sql = f.read()
    async with pool.acquire() as connection:
        await connection.execute(schema_sql)


@app.on_event("shutdown")
async def shutdown_event():
    await Database.disconnect()


@app.get("/", tags=["Root"])
async def root():
    return {"message": "Expense Tracker API Running", "version": "2.0.0"}


# Top-level /balance route (Flutter clients use this path)
from repositories.expense_repository import ExpenseRepository
from database import get_db_pool
from auth import get_current_user_id
import asyncpg

def _get_repo(pool: asyncpg.Pool = Depends(get_db_pool)) -> ExpenseRepository:
    return ExpenseRepository(pool)

@app.get("/balance", tags=["Balance"])
async def get_balance(repo: ExpenseRepository = Depends(_get_repo), user_id: int = Depends(get_current_user_id)):
    return await repo.get_balance_summary(user_id)


# Include all routers
app.include_router(auth_router)
app.include_router(expenses_router)
app.include_router(income_router)
app.include_router(budget_router)
app.include_router(goals_router)
app.include_router(subscriptions_router)
app.include_router(wallets_router)
app.include_router(debts_router)
app.include_router(categories_router)
app.include_router(health_router)
app.include_router(analytics_router)

if __name__ == "__main__":
    import uvicorn
    # Render provides the PORT environment variable. Default to 8000 for local development.
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
