
routes_code = '''
# --- Health Routes ---
def get_health_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> HealthRepository:
    return HealthRepository(pool)

@app.get("/health/metrics/{date_val}", response_model=Optional[HealthMetricsResponse])
async def get_health_metrics(
    date_val: date,
    repo: HealthRepository = Depends(get_health_repository),
    user_id: int = Depends(get_current_user_id)
):
    return await repo.get_health_metrics(user_id, date_val)

@app.post("/health/metrics", response_model=HealthMetricsResponse)
async def update_health_metrics(
    metrics: HealthMetricsCreate,
    repo: HealthRepository = Depends(get_health_repository),
    user_id: int = Depends(get_current_user_id)
):
    return await repo.create_or_update_metrics(user_id, metrics)

@app.get("/health/settings", response_model=HealthSettingsResponse)
async def get_health_settings(
    repo: HealthRepository = Depends(get_health_repository),
    user_id: int = Depends(get_current_user_id)
):
    return await repo.get_health_settings(user_id)

@app.post("/health/settings", response_model=HealthSettingsResponse)
async def update_health_settings(
    settings: HealthSettingsUpdate,
    repo: HealthRepository = Depends(get_health_repository),
    user_id: int = Depends(get_current_user_id)
):
    return await repo.update_health_settings(user_id, settings)
'''

with open('backend/main.py', 'r') as f:
    content = f.read()

if '# --- Health Routes ---' not in content:
    with open('backend/main.py', 'a') as f:
        f.write(routes_code)
    print("Routes appended.")
else:
    print("Routes already exist.")
