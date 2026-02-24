from typing import List, Optional
import asyncpg
from schemas.expense_schema import ExpenseCreate, ExpenseResponse, MonthlySummary
from schemas.income_schema import IncomeCreate, IncomeResponse
from schemas.budget_schema import BudgetCreate, BudgetResponse
from schemas.savings_goal_schema import SavingsGoalCreate, SavingsGoalResponse, ContributionRequest
from schemas.subscription_schema import SubscriptionCreate, SubscriptionResponse
from schemas.user_schema import UserCreate, UserResponse, Token
from schemas.debt_schema import DebtCreate, DebtUpdate
from datetime import datetime
from dateutil.relativedelta import relativedelta


class ExpenseRepository:
    def __init__(self, pool: asyncpg.Pool):
        self.pool = pool

    # --- Wallet Methods ---
    async def create_wallet(self, name: str, icon_code: int, color_value: int, balance: float, is_default: bool, user_id: int):
        query = """
            INSERT INTO wallets (name, icon_code, color_value, balance, is_default, user_id)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *;
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(query, name, icon_code, color_value, balance, is_default, user_id)
            if row:
                data = dict(row)
                data['balance'] = float(data['balance'])
                return data
            return None

    async def get_wallets(self, user_id: int):
        query = "SELECT * FROM wallets WHERE user_id = $1 ORDER BY is_default DESC, name ASC;"
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            res = []
            for row in rows:
                data = dict(row)
                data['balance'] = float(data['balance'])
                res.append(data)
            return res

    async def update_wallet(self, wallet_id: int, updates: dict, user_id: int):
        # Build dynamic update query based on fields provided
        if not updates:
            return None
        
        set_clauses = []
        values = []
        for i, (k, v) in enumerate(updates.items(), start=1):
            set_clauses.append(f"{k} = ${i}")
            values.append(v)
            
        values.extend([wallet_id, user_id])
        query = f"""
            UPDATE wallets SET {', '.join(set_clauses)}
            WHERE id = ${len(values)-1} AND user_id = ${len(values)}
            RETURNING *;
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(query, *values)
            if row:
                data = dict(row)
                data['balance'] = float(data['balance'])
                return data
            return None

    async def delete_wallet(self, wallet_id: int, user_id: int) -> bool:
        query = "DELETE FROM wallets WHERE id = $1 AND user_id = $2;"
        async with self.pool.acquire() as connection:
            result = await connection.execute(query, wallet_id, user_id)
            return result == "DELETE 1"



    # --- User Methods ---
    async def create_user(self, user: UserCreate, hashed_password: str) -> UserResponse:
        query = "INSERT INTO users (email, hashed_password) VALUES ($1, $2) RETURNING id, email;"
        async with self.pool.acquire() as connection:
            try:
                row = await connection.fetchrow(query, user.email, hashed_password)
                return UserResponse(**dict(row))
            except asyncpg.UniqueViolationError:
                return None

    async def get_user_by_email(self, email: str):
        query = "SELECT * FROM users WHERE email = $1;"
        async with self.pool.acquire() as connection:
            return await connection.fetchrow(query, email)

    # --- Expense Methods ---
    async def create_expense(self, expense: ExpenseCreate, user_id: int) -> ExpenseResponse:
        query = """
            INSERT INTO expenses (title, amount, category, date, notes, user_id, wallet_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, title, amount, category, date, notes, wallet_id;
        """
        date_val = expense.date or datetime.now()
        if date_val.tzinfo is not None:
            date_val = date_val.replace(tzinfo=None)
            
        async with self.pool.acquire() as connection:
            # First, check and deduct wallet balance if wallet_id is provided
            if expense.wallet_id:
                await connection.execute("UPDATE wallets SET balance = balance - $1 WHERE id = $2 AND user_id = $3", expense.amount, expense.wallet_id, user_id)
                
            row = await connection.fetchrow(
                query, expense.title, expense.amount, expense.category, date_val, expense.notes, user_id, expense.wallet_id
            )
            # Ensure amount is a float for JSON compatibility
            data = dict(row)
            data['amount'] = float(data['amount'])
            return ExpenseResponse(**data)

    async def get_expenses(self, user_id: int) -> List[ExpenseResponse]:
        # Explicitly list columns to match ExpenseResponse schema exactly
        query = "SELECT id, title, amount, category, date, notes, wallet_id FROM expenses WHERE user_id = $1 ORDER BY date DESC;"
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            result = []
            for row in rows:
                data = dict(row)
                data['amount'] = float(data['amount']) # Convert Decimal to float
                result.append(ExpenseResponse(**data))
            return result

    async def get_monthly_summary(self, user_id: int) -> List[MonthlySummary]:
        query = """
            SELECT TO_CHAR(date, 'YYYY-MM') as month, SUM(amount) as total_amount
            FROM expenses
            WHERE user_id = $1
            GROUP BY month
            ORDER BY month DESC;
        """
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            # Force total_amount to float to prevent JSON serialization errors
            return [MonthlySummary(month=row['month'], total_amount=float(row['total_amount'])) for row in rows]

    async def delete_expense(self, expense_id: int, user_id: int) -> bool:
        query = "DELETE FROM expenses WHERE id = $1 AND user_id = $2;"
        async with self.pool.acquire() as connection:
            result = await connection.execute(query, expense_id, user_id)
            return result == "DELETE 1"

    async def update_expense(self, expense_id: int, expense: ExpenseCreate, user_id: int) -> ExpenseResponse:
        query = """
            UPDATE expenses 
            SET title = $1, amount = $2, category = $3, date = $4, notes = $5
            WHERE id = $6 AND user_id = $7
            RETURNING id, title, amount, category, date, notes;
        """
        date_val = expense.date or datetime.now()
        if date_val.tzinfo is not None:
             date_val = date_val.replace(tzinfo=None)

        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(
                query, expense.title, expense.amount, expense.category, date_val, expense.notes, expense_id, user_id
            )
            if row:
                return ExpenseResponse(**dict(row))
            return None

    # --- Income Methods ---
    async def create_income(self, income: IncomeCreate, user_id: int) -> IncomeResponse:
        query = """
            INSERT INTO income (title, amount, category, date, notes, user_id, wallet_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, title, amount, category, date, notes, wallet_id;
        """
        date_val = income.date or datetime.now()
        if date_val.tzinfo is not None:
            date_val = date_val.replace(tzinfo=None)
            
        async with self.pool.acquire() as connection:
            if income.wallet_id:
                await connection.execute("UPDATE wallets SET balance = balance + $1 WHERE id = $2 AND user_id = $3", income.amount, income.wallet_id, user_id)
                
            row = await connection.fetchrow(
                query, income.title, income.amount, income.category, date_val, income.notes, user_id, income.wallet_id
            )
            return IncomeResponse(**dict(row))

    async def get_incomes(self, user_id: int):
        query = "SELECT * FROM income WHERE user_id = $1 ORDER BY date DESC;"
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            return [IncomeResponse(**dict(row)) for row in rows]

    async def update_income(self, income_id: int, income, user_id: int):
        query = """
            UPDATE income 
            SET title = $1, amount = $2, category = $3, date = $4, notes = $5
            WHERE id = $6 AND user_id = $7
            RETURNING id, title, amount, category, date, notes;
        """
        date_val = income.date or datetime.now()
        if date_val.tzinfo is not None:
             date_val = date_val.replace(tzinfo=None)

        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(
                query, income.title, income.amount, income.category, date_val, income.notes, income_id, user_id
            )
            if row:
                return IncomeResponse(**dict(row))
            return None

    async def delete_income(self, income_id: int, user_id: int) -> bool:
        query = "DELETE FROM income WHERE id = $1 AND user_id = $2;"
        async with self.pool.acquire() as connection:
            result = await connection.execute(query, income_id, user_id)
            return result == "DELETE 1"

    async def get_balance_summary(self, user_id: int):
        """Get total income and expenses for balance calculation"""
        async with self.pool.acquire() as connection:
            income_total = await connection.fetchval(
                "SELECT COALESCE(SUM(amount), 0) FROM income WHERE user_id = $1;", user_id
            )
            expense_total = await connection.fetchval(
                "SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE user_id = $1;", user_id
            )
            return {
                "total_income": float(income_total),
                "total_expenses": float(expense_total),
                "balance": float(income_total - expense_total)
            }

    # --- Savings Goal Methods ---
    async def create_goal(self, goal: SavingsGoalCreate, user_id: int) -> SavingsGoalResponse:
        # 1. Remove 'id' from the columns and the values list ($1)
        # 2. Re-number the placeholders starting from $1
        query = """
            INSERT INTO savings_goals (title, target_amount, current_amount, category, target_date, color_value, user_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, title, target_amount, current_amount, category, target_date, color_value;
        """
    
        target_date = goal.target_date.replace(tzinfo=None) if goal.target_date.tzinfo else goal.target_date

        async with self.pool.acquire() as connection:
            # Pass only the 7 parameters (exclude goal_id)
            row = await connection.fetchrow(
                query, 
                goal.title, 
                goal.target_amount, 
                goal.current_amount, 
                goal.category, 
                target_date, 
                goal.color_value, 
                user_id
            )
            
            if not row:
                raise Exception("Failed to insert row")

            data = dict(row)
            # Ensure decimals are floats for JSON serialization
            data['target_amount'] = float(data['target_amount'])
            data['current_amount'] = float(data['current_amount'])
            
            # This will now work because 'id' from RETURNING is an int, 
            # matching your updated SavingsGoalResponse(id: int)
            return SavingsGoalResponse(**data)

    async def get_goals(self, user_id: int) -> List[SavingsGoalResponse]:
        query = """
            SELECT id, title, target_amount, current_amount, category, target_date, color_value 
            FROM savings_goals 
            WHERE user_id = $1 
            ORDER BY target_date ASC;
        """
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            result = []
            for row in rows:
                data = dict(row)
                data['target_amount'] = float(data['target_amount'])
                data['current_amount'] = float(data['current_amount'])
                result.append(SavingsGoalResponse(**data))
            return result

    async def contribute_to_goal(self, goal_id: str, amount: float, user_id: int) -> dict:
        # 1. Added RETURNING * to get the updated data
        query = """
            UPDATE savings_goals 
            SET current_amount = current_amount + $1 
            WHERE id = $2 AND user_id = $3
            RETURNING id, title, target_amount, current_amount, category, target_date, color_value;
        """
        async with self.pool.acquire() as connection:
            # 2. Convert goal_id to int() here to prevent SQL type errors
            row = await connection.fetchrow(query, amount, int(goal_id), user_id)
            
            if not row:
                # If no row was updated (wrong ID or wrong user), this will trigger the 500
                raise Exception("Goal not found or unauthorized")
            
            # 3. Convert to dict and fix decimals for JSON
            data = dict(row)
            data['target_amount'] = float(data['target_amount'])
            data['current_amount'] = float(data['current_amount'])
            return data # This dict matches SavingsGoalResponse perfectly

    async def delete_goal(self, goal_id: str, user_id: int) -> bool:
        query = "DELETE FROM savings_goals WHERE id = $1 AND user_id = $2;"
        async with self.pool.acquire() as connection:
            result = await connection.execute(query, goal_id, user_id)
            return result == "DELETE 1"
    
    # --- Budget Methods ---

    async def set_budget(self, user_id: int, category: str, amount: float, month: int, year: int):
        """Creates or updates a budget limit for a specific category/month"""
        query = """
            INSERT INTO budgets (user_id, category, amount, month, year)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (user_id, category, month, year) 
            DO UPDATE SET amount = EXCLUDED.amount
            RETURNING id, category, amount, month, year;
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(query, user_id, category, amount, month, year)
            return dict(row)

    async def get_budget_status(self, user_id: int, month: int, year: int):
        """
        Calculates how much of the budget is spent for each category.
        This joins the budgets table with a sum of expenses for that specific month.
        """
        query = """
            SELECT 
                b.id,
                b.category,
                b.amount as limit_amount,
                COALESCE(e.total_spent, 0) as spent_amount,
                (b.amount - COALESCE(e.total_spent, 0)) as remaining_amount
            FROM budgets b
            LEFT JOIN (
                SELECT category, SUM(amount) as total_spent
                FROM expenses
                WHERE user_id = $1 
                AND EXTRACT(MONTH FROM date) = $2 
                AND EXTRACT(YEAR FROM date) = $3
                GROUP BY category
            ) e ON b.category = e.category
            WHERE b.user_id = $1 AND b.month = $2 AND b.year = $3;
        """
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id, month, year)
            return [
                {
                    "id": row['id'],
                    "category": row['category'],
                    "limit": float(row['limit_amount']),
                    "spent": float(row['spent_amount']),
                    "remaining": float(row['remaining_amount']),
                    "progress": float(row['spent_amount'] / row['limit_amount']) if row['limit_amount'] > 0 else 0
                } 
                for row in rows
            ]

    async def delete_budget(self, budget_id: int, user_id: int) -> bool:
        query = "DELETE FROM budgets WHERE id = $1 AND user_id = $2;"
        async with self.pool.acquire() as connection:
            result = await connection.execute(query, budget_id, user_id)
            return result == "DELETE 1"

    # --- Subscription Methods ---

    async def create_subscription(self, sub: SubscriptionCreate, user_id: int) -> SubscriptionResponse:
        query = """
            INSERT INTO subscriptions (title, amount, start_date, category, frequency, is_active, user_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, title, amount, start_date, category, frequency, is_active;
        """
        # Calculate next_payment_date - if start_date is in future, use it. If past, find next occurrence.
        date_val = sub.start_date.replace(tzinfo=None) if sub.start_date.tzinfo else sub.start_date
        now = datetime.now()
        next_payment = date_val
        
        # If start date is in the past, move next_payment to future or today?
        # Standard behavior: subscriptions start on start_date. If start date is past, we assume it was already paid?
        # Or processed immediately. For simplicity, let's say next payment is start_date if future, else...
        # Let's assume user enters start_date as the *first* payment.
        # We set next_payment_date = start_date initially. the check_recurring will pick it up if it's past/today.

        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(
                query, sub.title, sub.amount, date_val, sub.category, sub.frequency, sub.is_active, user_id
            )
            data = dict(row)
            data['amount'] = float(data['amount'])
            
            # Update the next_payment_date to start_date initially
            await connection.execute(
                "UPDATE subscriptions SET next_payment_date = $1 WHERE id = $2",
                date_val, data['id']
            )
            
            return SubscriptionResponse(**data)

    async def get_subscriptions(self, user_id: int) -> List[SubscriptionResponse]:
        query = """
            SELECT id, title, amount, start_date, category, frequency, is_active 
            FROM subscriptions 
            WHERE user_id = $1 
            ORDER BY start_date DESC;
        """
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            result = []
            for row in rows:
                data = dict(row)
                data['amount'] = float(data['amount'])
                # data['id'] = str(data['id'])
                result.append(SubscriptionResponse(**data))
            return result

    async def update_subscription(self, sub_id: int, sub: SubscriptionCreate, user_id: int) -> Optional[SubscriptionResponse]:
        query = """
            UPDATE subscriptions 
            SET title = $1, amount = $2, start_date = $3, category = $4, frequency = $5, is_active = $6
            WHERE id = $7 AND user_id = $8
            RETURNING id, title, amount, start_date, category, frequency, is_active;
        """
        date_val = sub.start_date.replace(tzinfo=None) if sub.start_date.tzinfo else sub.start_date

        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(
                query, sub.title, sub.amount, date_val, sub.category, sub.frequency, sub.is_active, sub_id, user_id
            )
            if row:
                data = dict(row)
                data['amount'] = float(data['amount'])
                # data['id'] = str(data['id'])
                return SubscriptionResponse(**data)
            return None

    async def delete_subscription(self, sub_id: int, user_id: int) -> bool:
        query = "DELETE FROM subscriptions WHERE id = $1 AND user_id = $2;"
        async with self.pool.acquire() as connection:
            result = await connection.execute(query, sub_id, user_id)
            return result == "DELETE 1"

    async def check_recurring_transactions(self, user_id: int):
        """Checks for due subscriptions and generates expenses."""
        now = datetime.now()
        
        # Select active subscriptions where next_payment_date <= NOW
        query = """
            SELECT * FROM subscriptions 
            WHERE user_id = $1 AND is_active = TRUE AND next_payment_date <= $2
        """
        
        created_expenses = []
        
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id, now)
            
            for row in rows:
                sub_id = row['id']
                amount = float(row['amount'])
                category = row['category']
                title = row['title']
                frequency = row['frequency']
                next_date = row['next_payment_date']
                
                # Logic: iterate until next_date is in the future
                # This handles cases where multiple periods were missed
                current_due = next_date
                
                while current_due <= now:
                    # Create Expense for this due date
                    expense = ExpenseCreate(
                        title=f"{title} (Recurring)",
                        amount=amount,
                        category=category,
                        date=current_due,
                        notes=f"Auto-generated from subscription: {title}"
                    )
                    
                    # Store expense using existing method (but we need connection or re-use code)
                    # Ideally call self.create_expense but that acquires new connection.
                    # Let's duplicate insert for efficiency or just use nested transaction if needed (asyncpg supports nested).
                    # Actually self.create_expense acquires a new connection from pool, which is fine.
                    # But better to do it here to ensure atomicity? No, separate transactions are fine for check.
                    # Let's just create the expense object and append to list to return
                    
                    # Insert Expense
                    await connection.execute("""
                        INSERT INTO expenses (title, amount, category, date, notes, user_id)
                        VALUES ($1, $2, $3, $4, $5, $6)
                    """, expense.title, expense.amount, expense.category, expense.date, expense.notes, user_id)
                    
                    created_expenses.append(expense)

                    # Calculate next due date
                    if frequency == 'weekly':
                        current_due += relativedelta(weeks=1)
                    elif frequency == 'yearly':
                        current_due += relativedelta(years=1)
                    else: # monthly
                        current_due += relativedelta(months=1)
                
                # Update subscription with new next_date
                await connection.execute(
                    "UPDATE subscriptions SET next_payment_date = $1 WHERE id = $2",
                    current_due, sub_id
                )
                
        return created_expenses

    # --- Analytics Methods ---
    async def get_category_breakdown(self, user_id: int):
        """Get expense breakdown by category"""
        query = """
            SELECT category, SUM(amount) as total, COUNT(*) as count
            FROM expenses
            WHERE user_id = $1
            GROUP BY category
            ORDER BY total DESC;
        """
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            return [{"category": row['category'], "total": float(row['total']), "count": row['count']} for row in rows]

    async def get_monthly_comparison(self, user_id: int, months: int = 6):
        """Get monthly income vs expenses comparison"""
        query = """
            SELECT 
                TO_CHAR(date, 'YYYY-MM') as month,
                'expense' as type,
                SUM(amount) as total
            FROM expenses
            WHERE user_id = $1 AND date >= CURRENT_DATE - INTERVAL '%s months'
            GROUP BY month
            UNION ALL
            SELECT 
                TO_CHAR(date, 'YYYY-MM') as month,
                'income' as type,
                SUM(amount) as total
            FROM income
            WHERE user_id = $1 AND date >= CURRENT_DATE - INTERVAL '%s months'
            GROUP BY month
            ORDER BY month DESC;
        """
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query.replace('%s', str(months)), user_id)
            return [{"month": row['month'], "type": row['type'], "total": float(row['total'])} for row in rows]

    async def get_insights(self, user_id: int):
        """Get key financial insights"""
        async with self.pool.acquire() as connection:
            # Current month stats
            current_month_expenses = await connection.fetchval(
                """SELECT COALESCE(SUM(amount), 0) FROM expenses 
                   WHERE user_id = $1 AND date >= DATE_TRUNC('month', CURRENT_DATE);""",
                user_id
            )
            current_month_income = await connection.fetchval(
                """SELECT COALESCE(SUM(amount), 0) FROM income 
                   WHERE user_id = $1 AND date >= DATE_TRUNC('month', CURRENT_DATE);""",
                user_id
            )
            
            # Last month stats
            last_month_expenses = await connection.fetchval(
                """SELECT COALESCE(SUM(amount), 0) FROM expenses 
                   WHERE user_id = $1 
                   AND date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
                   AND date < DATE_TRUNC('month', CURRENT_DATE);""",
                user_id
            )
            
            # Top spending category
            top_category = await connection.fetchrow(
                """SELECT category, SUM(amount) as total FROM expenses 
                   WHERE user_id = $1 AND date >= DATE_TRUNC('month', CURRENT_DATE)
                   GROUP BY category ORDER BY total DESC LIMIT 1;""",
                user_id
            )
            
            # Biggest expense
            biggest_expense = await connection.fetchrow(
                """SELECT title, amount, category FROM expenses 
                   WHERE user_id = $1 AND date >= DATE_TRUNC('month', CURRENT_DATE)
                   ORDER BY amount DESC LIMIT 1;""",
                user_id
            )
            
            # Average daily spending (current month)
            days_in_month = await connection.fetchval(
                "SELECT EXTRACT(DAY FROM CURRENT_DATE);"
            )
            avg_daily = float(current_month_expenses) / max(float(days_in_month), 1)
            
            # Savings rate
            savings_rate = 0
            if float(current_month_income) > 0:
                savings_rate = ((float(current_month_income) - float(current_month_expenses)) / float(current_month_income)) * 100
            
            return {
                "current_month_expenses": float(current_month_expenses),
                "current_month_income": float(current_month_income),
                "last_month_expenses": float(last_month_expenses),
                "expense_change": float(current_month_expenses) - float(last_month_expenses),
                "top_category": top_category['category'] if top_category else None,
                "top_category_amount": float(top_category['total']) if top_category else 0,
                "biggest_expense_title": biggest_expense['title'] if biggest_expense else None,
                "biggest_expense_amount": float(biggest_expense['amount']) if biggest_expense else 0,
                "biggest_expense_category": biggest_expense['category'] if biggest_expense else None,
                "average_daily_spending": avg_daily,
                "savings_rate": savings_rate
            }

    # --- Data Export Methods ---
    async def get_export_data(self, user_id: int) -> dict:
        """Fetch all financial data for export (CSV/JSON/Excel generation)"""
        async with self.pool.acquire() as connection:
            expenses = await connection.fetch(
                "SELECT id, title, amount, category, date, notes FROM expenses WHERE user_id = $1 ORDER BY date DESC",
                user_id
            )
            incomes = await connection.fetch(
                "SELECT id, title, amount, category, date, notes FROM income WHERE user_id = $1 ORDER BY date DESC",
                user_id
            )
            
            def serialize_row(row):
                data = dict(row)
                # Convert Decimal to float for JSON serialization
                if 'amount' in data and data['amount'] is not None:
                    data['amount'] = float(data['amount'])
                # Convert datetime to ISO string for JSON serialization
                if 'date' in data and data['date'] is not None:
                    data['date'] = data['date'].isoformat()
                return data
            
            return {
                "expenses": [serialize_row(row) for row in expenses],
                "income": [serialize_row(row) for row in incomes]
            }

    # --- Category Management Methods ---
    async def get_categories(self, user_id: int):
        query = "SELECT id, name, icon_code, color_value, type FROM categories WHERE user_id = $1 ORDER BY name;"
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            return [dict(row) for row in rows]

    async def create_category(self, user_id: int, name: str, icon_code: int, color_value: int, type: str):
        query = """
            INSERT INTO categories (user_id, name, icon_code, color_value, type)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, name, icon_code, color_value, type;
        """
        async with self.pool.acquire() as connection:
            try:
                row = await connection.fetchrow(query, user_id, name, icon_code, color_value, type)
                return dict(row)
            except asyncpg.UniqueViolationError:
                # If category exists, return the existing one or raise error?
                # For now, let's just return None to signal conflict
                return None

    async def delete_category(self, category_id: int, user_id: int) -> bool:
        query = "DELETE FROM categories WHERE id = $1 AND user_id = $2"
        async with self.pool.acquire() as connection:
            await connection.execute(query, category_id, user_id)

    # --- Debt Management ---
    async def create_debt(self, debt: DebtCreate, user_id: int):
        query = """
            INSERT INTO debts (user_id, title, amount, due_date, is_owed_by_me, status, notes)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *;
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(
                query, user_id, debt.title, debt.amount, debt.due_date, debt.is_owed_by_me, debt.status, debt.notes
            )
            return dict(row) if row else None

    async def get_debts(self, user_id: int):
        query = "SELECT * FROM debts WHERE user_id = $1 ORDER BY COALESCE(due_date, created_at) ASC"
        async with self.pool.acquire() as connection:
            rows = await connection.fetch(query, user_id)
            return [dict(row) for row in rows]

    async def update_debt(self, debt_id: int, updates: DebtUpdate, user_id: int):
        update_data = updates.dict(exclude_unset=True)
        wallet_id = update_data.pop('wallet_id', None)
        
        fields = []
        values = []
        idx = 1
        for k, v in update_data.items():
            if v is not None:
                fields.append(f"{k} = ${idx}")
                values.append(v)
                idx += 1
        
        if not fields:
            return None
            
        values.extend([debt_id, user_id])
        query = f"""
            UPDATE debts SET {', '.join(fields)}
            WHERE id = ${idx} AND user_id = ${idx+1}
            RETURNING *;
        """
        async with self.pool.acquire() as connection:
            async with connection.transaction():
                # Get existing debt to check if we are marking it paid
                existing_debt = await connection.fetchrow("SELECT amount, status, is_owed_by_me FROM debts WHERE id = $1 AND user_id = $2", debt_id, user_id)
                if not existing_debt:
                    return None
                    
                row = await connection.fetchrow(query, *values)
                
                # Check if we should update wallet
                if 'status' in update_data and update_data['status'] == 'paid' and existing_debt['status'] != 'paid' and wallet_id:
                    amount = existing_debt['amount']

                    # Debt (I owe someone money) -> paying it means my wallet balance goes down (-)
                    # Loan (Someone owes me money) -> they pay me, my wallet balance goes up (+)
                    if existing_debt['is_owed_by_me']:
                        await connection.execute("UPDATE wallets SET balance = balance - $1 WHERE id = $2 AND user_id = $3", amount, wallet_id, user_id)
                        # Maybe we could also automatically insert into expenses?
                    else:
                        await connection.execute("UPDATE wallets SET balance = balance + $1 WHERE id = $2 AND user_id = $3", amount, wallet_id, user_id)
                        # Maybe insert into incomes?

                return dict(row) if row else None

    async def delete_debt(self, debt_id: int, user_id: int):
        query = "DELETE FROM debts WHERE id = $1 AND user_id = $2"
        async with self.pool.acquire() as connection:
            result = await connection.execute(query, debt_id, user_id)
            return result == "DELETE 1"
