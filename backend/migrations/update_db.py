import asyncio
import os
from database import Database

async def update_schema():
    await Database.connect()
    pool = await Database.get_pool()
    async with pool.acquire() as connection:
        try:
            print("Adding next_payment_date column...")
            await connection.execute("""
                ALTER TABLE subscriptions 
                ADD COLUMN IF NOT EXISTS next_payment_date TIMESTAMP;
            """)
            print("Added next_payment_date column.")

            print("Updating existing records...")
            await connection.execute("""
                UPDATE subscriptions 
                SET next_payment_date = start_date 
                WHERE next_payment_date IS NULL;
            """)
            print("Initialized next_payment_date for existing subscriptions.")
            
        except Exception as e:
            print(f"Error updating schema: {e}")
    await Database.disconnect()

if __name__ == "__main__":
    asyncio.run(update_schema())
