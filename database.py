import os
from sqlmodel import SQLModel, create_engine, Session

sqlite_file_name = "freetier_radar.db"
default_url = f"sqlite:///{sqlite_file_name}"
sqlite_url = os.getenv("DATABASE_URL", default_url)

echo_str = os.getenv("DB_ECHO", "False").lower()
echo_val = echo_str in ("true", "1", "yes")

connect_args = {"check_same_thread": False} if sqlite_url.startswith("sqlite") else {}
engine = create_engine(sqlite_url, echo=echo_val, connect_args=connect_args)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
