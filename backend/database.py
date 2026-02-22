import os
import asyncpg
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost:5432/expenses")

class Database:
    pool: asyncpg.Pool = None

    @classmethod
    async def connect(cls):
        if cls.pool is None:
            cls.pool = await asyncpg.create_pool(DATABASE_URL)
            print("Database connection pool created.")

    @classmethod
    async def disconnect(cls):
        if cls.pool:
            await cls.pool.close()
            print("Database connection pool closed.")

    @classmethod
    def get_pool(cls):
        return cls.pool

async def get_db_pool():
    if Database.pool is None:
        await Database.connect()
    return Database.pool
