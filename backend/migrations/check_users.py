import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def check_users():
    """Check if there are any users in the database"""
    conn = await asyncpg.connect(os.getenv("DATABASE_URL"))
    
    try:
        # Get all users
        users = await conn.fetch("SELECT id, email FROM users;")
        
        if not users:
            print("No users found in database!")
            print("You need to register a user first before logging in.")
        else:
            print(f"Found {len(users)} user(s) in database:")
            for user in users:
                print(f"  - ID: {user['id']}, Email: {user['email']}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(check_users())
