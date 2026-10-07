import os
import sys
import time
import asyncio
import logging
from datetime import datetime, timezone
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, Depends, Query, Request, HTTPException, BackgroundTasks, Security, status
from fastapi.security.api_key import APIKeyHeader
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from sqlmodel import Session, select, or_, text

from database import engine, create_db_and_tables, get_session
from models import (
    ServiceItem, ServiceCategory, ServiceStatus, ServiceItemRead, ServiceItemList,
    DeprecationAlert, DeprecationAlertRead, ServiceReport, ReportCreate
)
from scrapers.github_freedev_parser import parse_free_for_dev
from scrapers.targeted_scrapers import run_targeted_scrapers
from diff_engine import detect_tier_changes, compute_content_hash
from services.notification import send_tier_alert

# ---------------------------------------------------------
# Enterprise Observability: ISO-8601 Structured Logging
# ---------------------------------------------------------
class ISO8601Formatter(logging.Formatter):
    def formatTime(self, record, datefmt=None):
        dt = datetime.fromtimestamp(record.created, timezone.utc)
        return dt.isoformat()

logger = logging.getLogger("freetier_radar")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(ISO8601Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s"))
if not logger.handlers:
    logger.addHandler(handler)

# ---------------------------------------------------------
# Security & Rate Limiting
# ---------------------------------------------------------
SYNC_SECRET_KEY = os.getenv("SYNC_SECRET_KEY", "default-insecure-secret-if-unconfigured")
sync_api_key_header = APIKeyHeader(name="X-Sync-Token", auto_error=True)

limiter = Limiter(key_func=get_remote_address)

async def verify_sync_token(api_key: str = Security(sync_api_key_header)):
    if api_key != SYNC_SECRET_KEY:
        raise HTTPException(status_code=403, detail="Invalid or missing sync token")
    return api_key

# ---------------------------------------------------------
# Background Sync Logic & Concurrency Lock
# ---------------------------------------------------------
is_syncing = False
sync_lock = asyncio.Lock()

async def sync_wrapper():
    global is_syncing
    try:
        await run_sync_pipeline()
    except Exception as e:
        logger.error(f"Sync pipeline failed with error: {e}", exc_info=True)
    finally:
        async with sync_lock:
            is_syncing = False

async def run_sync_pipeline():
    """Runs both the GitHub scraper and Targeted scrapers, then diffs the results."""
    logger.info("Starting automated sync pipeline...")
    with Session(engine) as session:
        # 1. Targeted Scrapers
        targeted_data = await run_targeted_scrapers()
        
        # 2. GitHub Bulk Scraper
        github_services = await parse_free_for_dev()
        
        # Upsert targeted data first
        for data in targeted_data:
            statement = select(ServiceItem).where(ServiceItem.name == data["service_name"])
            existing = session.exec(statement).first()
            new_hash = compute_content_hash(data["raw_text"])
            
            if existing:
                existing.free_tier_limits = data["raw_text"]
                existing.pricing_url = data["url"]
                existing.content_hash = new_hash
                existing.last_scraped_at = datetime.now(timezone.utc)
                existing.last_verified_at = datetime.now(timezone.utc)
                session.add(existing)
            else:
                new_svc = ServiceItem(
                    name=data["service_name"],
                    category=ServiceCategory.OTHER,
                    short_description="Directly scraped pricing",
                    free_tier_limits=data["raw_text"],
                    official_url=data["url"],
                    pricing_url=data["url"],
                    content_hash=new_hash,
                    last_scraped_at=datetime.now(timezone.utc)
                )
                session.add(new_svc)

        # Upsert and diff logic for Github services
        for new_svc in github_services:
            statement = select(ServiceItem).where(ServiceItem.name == new_svc.name)
            existing = session.exec(statement).first()
            
            new_hash = compute_content_hash(new_svc.free_tier_limits)
            
            if existing:
                # Diff check
                alert = detect_tier_changes(existing, new_svc.free_tier_limits)
                if alert:
                    session.add(alert)
                    existing.status = ServiceStatus.DEPRECATED if alert.alert_type == 'TIER_DOWNGRADE' else ServiceStatus.CHANGED_RECENTLY
                    existing.change_log_summary = alert.summary
                    
                    # Fire Webhooks
                    await send_tier_alert(
                        service_name=existing.name,
                        old_limit=alert.old_limit or existing.free_tier_limits,
                        new_limit=alert.new_limit or new_svc.free_tier_limits,
                        url=existing.official_url,
                        alert_type=alert.alert_type,
                        timestamp=alert.detected_at
                    )
                
                # Update existing
                existing.free_tier_limits = new_svc.free_tier_limits
                existing.content_hash = new_hash
                existing.last_scraped_at = datetime.now(timezone.utc)
                existing.last_verified_at = datetime.now(timezone.utc)
                session.add(existing)
            else:
                # Insert new
                new_svc.content_hash = new_hash
                new_svc.last_scraped_at = datetime.now(timezone.utc)
                session.add(new_svc)
        
        session.commit()
        logger.info("Automated sync pipeline completed.")

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield

# ---------------------------------------------------------
# FastAPI App Initialization & OpenAPI Metadata
# ---------------------------------------------------------
tags_metadata = [
    {"name": "Services", "description": "Discover and filter free-tier tools."},
    {"name": "Alerts", "description": "Deprecation radar and quota downgrade notifications."},
    {"name": "Engine", "description": "Admin triggers and scraper sync."},
    {"name": "Health", "description": "Liveness and readiness monitoring."}
]

app = FastAPI(
    title="FreeTier Radar API",
    description="End-to-end mobile application backend pipeline that scrapes, normalizes, and categorizes free-tier developer services.",
    version="1.0.0",
    contact={"name": "API Support", "email": "support@freetier.radar"},
    license_info={"name": "MIT", "url": "https://opensource.org/licenses/MIT"},
    openapi_tags=tags_metadata,
    lifespan=lifespan
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# ---------------------------------------------------------
# API Endpoints
# ---------------------------------------------------------

@app.get("/health/live", tags=["Health"])
def health_live():
    return {"status": "alive"}

@app.get("/health/ready", tags=["Health"])
def health_ready(session: Session = Depends(get_session)):
    try:
        session.exec(text("SELECT 1")).first()
        return {"status": "ready", "database": "connected"}
    except Exception as e:
        logger.error(f"Readiness probe failed: {e}")
        raise HTTPException(status_code=503, detail="Database unavailable")

# Fallback backwards-compatible health route
@app.get("/health", tags=["Health"], include_in_schema=False)
def health_check():
    return {"status": "ok", "service": "FreeTier Radar API", "version": "1.2.0"}

@app.get("/api/v1/services", response_model=ServiceItemList, tags=["Services"])
@limiter.limit("60/minute")
def get_services(
    request: Request,
    category: Optional[ServiceCategory] = None,
    no_credit_card: Optional[bool] = None,
    search: Optional[str] = Query(None, alias="query"), 
    status: Optional[ServiceStatus] = None,
    page: int = 1,
    page_size: int = 20,
    session: Session = Depends(get_session)
):
    query_obj = select(ServiceItem)
    
    if category:
        query_obj = query_obj.where(ServiceItem.category == category)
    if no_credit_card is not None:
        query_obj = query_obj.where(ServiceItem.requires_credit_card == (not no_credit_card))
    if status:
        query_obj = query_obj.where(ServiceItem.status == status)
    if search:
        search_pattern = f"%{search}%"
        query_obj = query_obj.where(
            or_(
                ServiceItem.name.ilike(search_pattern),
                ServiceItem.short_description.ilike(search_pattern),
                ServiceItem.free_tier_limits.ilike(search_pattern)
            )
        )
        
    total = len(session.exec(query_obj).all())
    query_obj = query_obj.offset((page - 1) * page_size).limit(page_size)
    items = session.exec(query_obj).all()
    
    return ServiceItemList(items=items, total=total, page=page, page_size=page_size)

@app.get("/api/v1/alerts/deprecations", response_model=list[DeprecationAlertRead], tags=["Alerts"])
@limiter.limit("60/minute")
def get_alerts_deprecations(request: Request, session: Session = Depends(get_session)):
    statement = select(DeprecationAlert).order_by(DeprecationAlert.detected_at.desc()).limit(50)
    return session.exec(statement).all()

@app.get("/api/v1/alerts", response_model=list[DeprecationAlertRead], tags=["Alerts"])
@limiter.limit("60/minute")
def get_alerts(request: Request, session: Session = Depends(get_session)):
    statement = select(DeprecationAlert).order_by(DeprecationAlert.detected_at.desc()).limit(50)
    return session.exec(statement).all()

@app.post("/api/v1/sync", status_code=status.HTTP_202_ACCEPTED, tags=["Engine"])
async def force_sync(
    request: Request, 
    background_tasks: BackgroundTasks, 
    token: str = Depends(verify_sync_token)
):
    """
    Manual trigger endpoint to run the scrapers and diff engine. 
    Secured via X-Sync-Token. Uses a non-blocking background task.
    """
    global is_syncing
    async with sync_lock:
        if is_syncing:
            raise HTTPException(status_code=409, detail="A sync process is already running")
        is_syncing = True
        
    background_tasks.add_task(sync_wrapper)
    
    return {
        "status": "accepted", 
        "message": "Scrape and sync cycle triggered in background", 
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

@app.post("/api/v1/reports", status_code=201, tags=["Community"])
@limiter.limit("5/minute")
def submit_report(
    request: Request,
    report: ReportCreate,
    session: Session = Depends(get_session)
):
    """Submit a community report for a service (e.g., outdated pricing, broken links)."""
    new_report = ServiceReport(
        service_id=report.service_id,
        report_type=report.report_type,
        message=report.message
    )
    session.add(new_report)
    session.commit()
    logger.info(f"New community report received for service {report.service_id}: {report.report_type}")
    return {"status": "success", "message": "Report submitted successfully"}
