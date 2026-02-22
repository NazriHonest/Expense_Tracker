import asyncio
from database import get_db_pool

async def update_schema():
    pool = await get_db_pool()
    async with pool.acquire() as connection:
        # Create categories table
        try:
            print("Creating categories table...")
            await connection.execute("""
                CREATE TABLE IF NOT EXISTS categories (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                    name VARCHAR(100) NOT NULL,
                    icon_code INTEGER NOT NULL, -- unique code mapping to Flutter IconData
                    color_value BIGINT NOT NULL, -- hex color integer
                    type VARCHAR(20) NOT NULL DEFAULT 'expense', -- 'expense' or 'income'
                    UNIQUE(user_id, name, type)
                );
            """)
            print("Categories table created.")
            
            # Populate default categories for existing users?
            # Or handle it lazily. Let's populate defaults for users who have none.
            # For simplicity, we'll let frontend handle defaults if backend returns empty list.
            
        except Exception as e:
            print(f"Error updating schema: {e}")

if __name__ == "__main__":
    asyncio.run(update_schema())
