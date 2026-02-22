from fastapi import APIRouter, Depends
from typing import Optional
from datetime import date

from repositories.health_repository import HealthRepository
from schemas.health_schema import (
    HealthMetricsCreate,
    HealthMetricsResponse,
    HealthSettingsUpdate,
    HealthSettingsResponse,
)
from auth import get_current_user_id
from database import get_db_pool
import asyncpg

router = APIRouter(prefix="/health", tags=["Health"])


def get_health_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> HealthRepository:
    return HealthRepository(pool)


@router.get("/metrics/{date_val}", response_model=Optional[HealthMetricsResponse])
async def get_health_metrics(
    date_val: date,
    repo: HealthRepository = Depends(get_health_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_health_metrics(user_id, date_val)


@router.post("/metrics", response_model=HealthMetricsResponse)
async def update_health_metrics(
    metrics: HealthMetricsCreate,
    repo: HealthRepository = Depends(get_health_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.create_or_update_metrics(user_id, metrics)


@router.get("/settings", response_model=HealthSettingsResponse)
async def get_health_settings(
    repo: HealthRepository = Depends(get_health_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.get_health_settings(user_id)


@router.post("/settings", response_model=HealthSettingsResponse)
async def update_health_settings(
    settings: HealthSettingsUpdate,
    repo: HealthRepository = Depends(get_health_repository),
    user_id: int = Depends(get_current_user_id),
):
    return await repo.update_health_settings(user_id, settings)
