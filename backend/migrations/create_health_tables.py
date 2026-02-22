import asyncio
import os
import asyncpg
from dotenv import load_dotenv

load_dotenv()

async def get_db_pool():
    if not os.getenv("DATABASE_URL"):
        raise ValueError("DATABASE_URL environment variable not set")
    return await asyncpg.create_pool(os.getenv("DATABASE_URL"))

async def create_health_tables():
    print("Connecting to database...")
    try:
        pool = await get_db_pool()
        async with pool.acquire() as connection:
            print("Creating health_metrics table...")
            await connection.execute("""
                CREATE TABLE IF NOT EXISTS health_metrics (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                    date DATE NOT NULL,
                    water_intake INTEGER DEFAULT 0,
                    steps INTEGER DEFAULT 0,
                    sleep_hours DECIMAL(4, 2) DEFAULT 0.0,
                    mood VARCHAR(50),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, date)
                );
            """)

            print("Creating health_settings table...")
            await connection.execute("""
                CREATE TABLE IF NOT EXISTS health_settings (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                    water_goal INTEGER DEFAULT 2500,
                    reminder_interval INTEGER DEFAULT 60, -- minutes
                    break_interval INTEGER DEFAULT 60,
                    exercise_reminder BOOLEAN DEFAULT TRUE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id)
                );
            """)
            
            print("Health tables created successfully!")
            
    except Exception as e:
        print(f"Error creating health tables: {e}")

if __name__ == "__main__":
    asyncio.run(create_health_tables())
