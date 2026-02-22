
import asyncio
import os
import asyncpg
from dotenv import load_dotenv

# Load env same as database.py
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost:5432/expenses")

async def reset_db():
    print(f"Connecting to {DATABASE_URL}...")
    try:
        conn = await asyncpg.connect(DATABASE_URL)
        
        # Read schema
        schema_path = os.path.join(os.path.dirname(__file__), "schema.sql")
        with open(schema_path, "r") as f:
            schema_sql = f.read()
            
        print("Applying schema (Dropping & Recreating tables)...")
        await conn.execute(schema_sql)
        print("Database reset successfully!")
        
        await conn.close()
    except Exception as e:
        print(f"Error resetting DB: {e}")

if __name__ == "__main__":
    asyncio.run(reset_db())
