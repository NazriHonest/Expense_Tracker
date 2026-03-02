from datetime import datetime, timezone
from typing import Optional


def normalize_datetime(dt: Optional[datetime]) -> Optional[datetime]:
    """
    Convert a datetime to offset-naive (strip timezone info) for PostgreSQL storage.
    
    PostgreSQL TIMESTAMP columns are offset-naive. This function ensures
    consistent datetime handling by converting offset-aware datetimes to 
    offset-naive (UTC-based).
    
    Args:
        dt: Input datetime (may be offset-aware or offset-naive)
        
    Returns:
        Offset-naive datetime in UTC, or None if input is None
    """
    if dt is None:
        return None
    
    if dt.tzinfo is not None:
        # Convert to UTC first, then strip timezone info
        return dt.astimezone(timezone.utc).replace(tzinfo=None)
    
    return dt


def get_utc_now() -> datetime:
    """
    Get current UTC time as offset-naive datetime.
    
    Returns:
        Current UTC time without timezone info (for PostgreSQL compatibility)
    """
    return datetime.now(timezone.utc).astimezone(timezone.utc).replace(tzinfo=None)
