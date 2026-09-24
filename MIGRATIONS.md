"""
Alembic database migration configuration.

Run:
  alembic init alembic       # (Already done)
  alembic revision --autogenerate -m "initial"
  alembic upgrade head
"""

# This file serves as documentation for setting up Alembic migrations.
#
# Steps to enable Alembic:
#
# 1. Install: pip install alembic
# 2. Initialize: cd backend && alembic init alembic
# 3. Edit alembic/env.py:
#    - Add: from models import ServiceItem, DeprecationAlert
#    - Add: from database import engine
#    - Set: target_metadata = SQLModel.metadata
#    - Set: config.set_main_option("sqlalchemy.url", str(engine.url))
# 4. Generate migration: alembic revision --autogenerate -m "initial schema"
# 5. Apply: alembic upgrade head
#
# For subsequent schema changes:
#    alembic revision --autogenerate -m "description of change"
#    alembic upgrade head
