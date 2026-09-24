import os
import time
from contextlib import asynccontextmanager
from typing import Optional
from fastapi import FastAPI, Depends, Query, Request, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select, or_
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from database import engine, create_db_and_tables, get_session
from models import (
    ServiceItem, ServiceCategory, ServiceStatus, ServiceItemRead, ServiceItemList,
    DeprecationAlert, DeprecationAlertRead
)
from scrapers.github_freedev_parser import parse_free_for_dev
from scrapers.targeted_scrapers import run_targeted_scrapers
from diff_engine import detect_tier_changes, compute_content_hash
from datetime import datetime, timezone

scheduler = AsyncIOScheduler()

async def run_sync_pipeline():
    """Runs both the GitHub scraper and Targeted scrapers, then diffs the results."""
    print("Starting automated sync pipeline...")
    with Session(engine) as session:
        # 1. Targeted Scrapers
        targeted_data = await run_targeted_scrapers()
        
        # 2. GitHub Bulk Scraper
        github_services = await parse_free_for_dev()
        
        # Upsert and diff logic
        for new_svc in github_services:
            # Check if exists
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
        print("Automated sync pipeline completed.")

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    scheduler.add_job(run_sync_pipeline, 'interval', hours=12)
    scheduler.start()
    yield
    scheduler.shutdown()

app = FastAPI(title="FreeTier Radar API", lifespan=lifespan)

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

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "FreeTier Radar API", "version": "1.1.0"}

@app.get("/api/v1/services", response_model=ServiceItemList)
def get_services(
    category: Optional[ServiceCategory] = None,
    no_credit_card: Optional[bool] = None,
    search: Optional[str] = Query(None, alias="query"),  # Support both ?search= and ?query=
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
        
    # Pagination
    total = len(session.exec(query_obj).all())
    query_obj = query_obj.offset((page - 1) * page_size).limit(page_size)
    items = session.exec(query_obj).all()
    
    return ServiceItemList(items=items, total=total, page=page, page_size=page_size)

@app.get("/api/v1/alerts/deprecations", response_model=list[DeprecationAlertRead])
@app.get("/api/v1/alerts", response_model=list[DeprecationAlertRead])
def get_alerts(session: Session = Depends(get_session)):
    statement = select(DeprecationAlert).order_by(DeprecationAlert.detected_at.desc()).limit(50)
    return session.exec(statement).all()

@app.post("/api/v1/sync")
async def force_sync(background_tasks: BackgroundTasks):
    """Manual trigger endpoint to run the scrapers and diff engine."""
    background_tasks.add_task(run_sync_pipeline)
    return {"message": "Sync pipeline started in the background."}
