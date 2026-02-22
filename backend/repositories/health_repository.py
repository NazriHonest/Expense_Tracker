from typing import List, Optional
import asyncpg
from schemas.health_schema import (
    HealthMetricsCreate, HealthMetricsResponse, 
    HealthSettingsUpdate, HealthSettingsResponse
)
from datetime import date, datetime

class HealthRepository:
    def __init__(self, pool: asyncpg.Pool):
        self.pool = pool

    async def get_health_metrics(self, user_id: int, date_val: date) -> Optional[HealthMetricsResponse]:
        query = """
            SELECT id, user_id, date, water_intake, steps, sleep_hours, mood, calories_burned, active_minutes, created_at
            FROM health_metrics
            WHERE user_id = $1 AND date = $2
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(query, user_id, date_val)
            if row:
                data = dict(row)
                data['sleep_hours'] = float(data['sleep_hours'])
                return HealthMetricsResponse(**data)
            return None

    async def create_or_update_metrics(self, user_id: int, metrics: HealthMetricsCreate) -> HealthMetricsResponse:
        query = """
            INSERT INTO health_metrics (user_id, date, water_intake, steps, sleep_hours, mood, calories_burned, active_minutes)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            ON CONFLICT (user_id, date) 
            DO UPDATE SET 
                water_intake = EXCLUDED.water_intake,
                steps = EXCLUDED.steps,
                sleep_hours = EXCLUDED.sleep_hours,
                mood = EXCLUDED.mood,
                calories_burned = EXCLUDED.calories_burned,
                active_minutes = EXCLUDED.active_minutes
            RETURNING id, user_id, date, water_intake, steps, sleep_hours, mood, calories_burned, active_minutes, created_at;
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(
                query, user_id, metrics.date, metrics.water_intake, metrics.steps, metrics.sleep_hours, metrics.mood, metrics.calories_burned, metrics.active_minutes
            )
            data = dict(row)
            data['sleep_hours'] = float(data['sleep_hours'])
            return HealthMetricsResponse(**data)

    async def get_health_settings(self, user_id: int) -> HealthSettingsResponse:
        query = """
            SELECT id, user_id, water_goal, steps_goal, sleep_goal, reminder_interval, break_interval, exercise_reminder, created_at
            FROM health_settings
            WHERE user_id = $1
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(query, user_id)
            if row:
                return HealthSettingsResponse(**dict(row))
            
            # Create default settings if not exists
            return await self.create_health_settings(user_id)

    async def create_health_settings(self, user_id: int) -> HealthSettingsResponse:
        query = """
            INSERT INTO health_settings (user_id) VALUES ($1)
            RETURNING id, user_id, water_goal, steps_goal, sleep_goal, reminder_interval, break_interval, exercise_reminder, created_at;
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(query, user_id)
            return HealthSettingsResponse(**dict(row))

    async def update_health_settings(self, user_id: int, settings: HealthSettingsUpdate) -> HealthSettingsResponse:
        query = """
            INSERT INTO health_settings (user_id, water_goal, steps_goal, sleep_goal, reminder_interval, break_interval, exercise_reminder)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (user_id)
            DO UPDATE SET
                water_goal = EXCLUDED.water_goal,
                steps_goal = EXCLUDED.steps_goal,
                sleep_goal = EXCLUDED.sleep_goal,
                reminder_interval = EXCLUDED.reminder_interval,
                break_interval = EXCLUDED.break_interval,
                exercise_reminder = EXCLUDED.exercise_reminder
            RETURNING id, user_id, water_goal, steps_goal, sleep_goal, reminder_interval, break_interval, exercise_reminder, created_at;
        """
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(
                query, user_id, settings.water_goal, settings.steps_goal, settings.sleep_goal, settings.reminder_interval, settings.break_interval, settings.exercise_reminder
            )
            return HealthSettingsResponse(**dict(row))
