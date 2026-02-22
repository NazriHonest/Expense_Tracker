import asyncio
import os
from database import get_db_pool
from dotenv import load_dotenv

load_dotenv()

async def update_schema():
    print("Connecting to database...")
    try:
        pool = await get_db_pool()
        async with pool.acquire() as connection:
            print("Creating wallets table...")
            await connection.execute("""
                CREATE TABLE IF NOT EXISTS wallets (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                    name VARCHAR(100) NOT NULL,
                    icon_code INTEGER DEFAULT 57544,
                    color_value BIGINT DEFAULT 4280391411,
                    balance DECIMAL(15, 2) DEFAULT 0.0,
                    is_default BOOLEAN DEFAULT FALSE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            print("Wallets table created.")

            # Add wallet_id to expenses if not exists
            try:
                await connection.execute("ALTER TABLE expenses ADD COLUMN wallet_id INTEGER REFERENCES wallets(id) ON DELETE SET NULL;")
                print("Added wallet_id to expenses.")
            except Exception as e:
                print(f"Column may already exist in expenses: {e}")

            # Add wallet_id to income if not exists
            try:
                await connection.execute("ALTER TABLE income ADD COLUMN wallet_id INTEGER REFERENCES wallets(id) ON DELETE SET NULL;")
                print("Added wallet_id to income.")
            except Exception as e:
                print(f"Column may already exist in income: {e}")

            print("Database schema update for wallets complete!")
            
    except Exception as e:
        print(f"Error updating schema: {e}")

if __name__ == "__main__":
    asyncio.run(update_schema())
