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
        
        # Create debts table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS debts (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                title VARCHAR(255) NOT NULL,
                amount NUMERIC(15, 2) NOT NULL,
                due_date TIMESTAMP,
                is_owed_by_me BOOLEAN NOT NULL DEFAULT TRUE,
                status VARCHAR(50) NOT NULL DEFAULT 'pending',
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        print("Table 'debts' created successfully.")
        
        await conn.close()
        print("Database connection closed.")
        
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    asyncio.run(update_schema())
