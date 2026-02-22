import asyncio
import os
import asyncpg
from dotenv import load_dotenv

load_dotenv()

async def update_schema():
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("DATABASE_URL environment variable is not set.")
        return

    print("Connecting to database...")
    try:
        conn = await asyncpg.connect(database_url)
        print("Connected.")
        
        # Add columns if they don't exist
        await conn.execute("""
            ALTER TABLE health_settings
            ADD COLUMN IF NOT EXISTS steps_goal INTEGER DEFAULT 10000,
            ADD COLUMN IF NOT EXISTS sleep_goal NUMERIC(4,1) DEFAULT 8.0;
        """)
        
        # Add new habits columns to metrics
        await conn.execute("""
            ALTER TABLE health_metrics
            ADD COLUMN IF NOT EXISTS calories_burned INTEGER DEFAULT 0,
            ADD COLUMN IF NOT EXISTS active_minutes INTEGER DEFAULT 0;
        """)
        print("Health schema updated successfully.")
        
        await conn.close()
        print("Database connection closed.")
        
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    asyncio.run(update_schema())
