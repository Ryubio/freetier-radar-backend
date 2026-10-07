from typing import Optional, List
from sqlmodel import SQLModel, Field, Session, select
from enum import Enum
from datetime import datetime, timezone
import uuid

# Enums
class ServiceCategory(str, Enum):
    AI_ML = "AI_ML"
    DATABASES = "DATABASES"
    HOSTING_PAAS = "HOSTING_PAAS"
    AUTH_SECURITY = "AUTH_SECURITY"
    STORAGE_CDN = "STORAGE_CDN"
    APIS_DEVTOOLS = "APIS_DEVTOOLS"
    CREATIVE_ASSETS = "CREATIVE_ASSETS"
    OTHER = "OTHER"

class ServiceStatus(str, Enum):
    ACTIVE = "ACTIVE"
    DEPRECATED = "DEPRECATED"
    CHANGED_RECENTLY = "CHANGED_RECENTLY"

def _utcnow():
    return datetime.now(timezone.utc)

# Database Models
class ServiceItem(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    name: str = Field(index=True)
    category: ServiceCategory = Field(default=ServiceCategory.OTHER)
    short_description: str = Field(max_length=255)
    free_tier_limits: str
    requires_credit_card: bool = Field(default=False)
    has_hard_cap: bool = Field(default=True)
    official_url: str
    pricing_url: Optional[str] = None
    status: ServiceStatus = Field(default=ServiceStatus.ACTIVE)
    change_log_summary: Optional[str] = None
    
    # New fields from spec
    content_hash: Optional[str] = None
    last_scraped_at: Optional[datetime] = None
    
    last_verified_at: datetime = Field(default_factory=_utcnow)
    created_at: datetime = Field(default_factory=_utcnow)

class DeprecationAlert(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    service_id: str = Field(index=True)
    
    # New fields from spec
    service_name: str
    old_limit: Optional[str] = None
    new_limit: Optional[str] = None
    
    alert_type: str  # TIER_DOWNGRADE, DEPRECATED, TIER_UPGRADE
    summary: str
    detected_at: datetime = Field(default_factory=_utcnow)
    previous_hash: Optional[str] = None
    current_hash: Optional[str] = None

# Pydantic Read Models
class ServiceItemRead(SQLModel):
    id: str
    name: str
    category: ServiceCategory
    short_description: str
    free_tier_limits: str
    requires_credit_card: bool
    has_hard_cap: bool
    official_url: str
    pricing_url: Optional[str] = None
    status: ServiceStatus
    change_log_summary: Optional[str] = None
    content_hash: Optional[str] = None
    last_scraped_at: Optional[datetime] = None
    last_verified_at: datetime
    created_at: datetime

class ServiceItemList(SQLModel):
    items: List[ServiceItemRead]
    total: int
    page: int
    page_size: int

class DeprecationAlertRead(SQLModel):
    id: str
    service_id: str
    service_name: str
    old_limit: Optional[str]
    new_limit: Optional[str]
    alert_type: str
    summary: str
    detected_at: datetime

class ServiceReport(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    service_id: str = Field(index=True)
    report_type: str  # e.g., "OUTDATED_PRICING", "BROKEN_LINK", "OTHER"
    message: str
    is_resolved: bool = Field(default=False)
    created_at: datetime = Field(default_factory=_utcnow)

class ReportCreate(SQLModel):
    service_id: str
    report_type: str
    message: str
