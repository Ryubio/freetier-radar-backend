import os
import urllib.parse
from sqlmodel import SQLModel, create_engine, Session

# 1. Dynamically load connection string
raw_db_url = os.getenv("DATABASE_URL")
sqlite_file_name = "freetier_radar.db"

if raw_db_url:
    # 2. Automatically fix provider prefixes (Render/Heroku compatibility)
    if raw_db_url.startswith("postgres://"):
        raw_db_url = raw_db_url.replace("postgres://", "postgresql+psycopg2://", 1)
    
    # Enable resilient connection pooling for cloud databases
    engine = create_engine(
        raw_db_url, 
        pool_pre_ping=True, 
        pool_recycle=300
    )
else:
    # Fallback to local SQLite
    raw_db_url = f"sqlite:///./{sqlite_file_name}"
    echo_str = os.getenv("DB_ECHO", "False").lower()
    echo_val = echo_str in ("true", "1", "yes")
    connect_args = {"check_same_thread": False}
    engine = create_engine(
        raw_db_url, 
        echo=echo_val, 
        connect_args=connect_args,
        pool_pre_ping=True, 
        pool_recycle=300
    )

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
