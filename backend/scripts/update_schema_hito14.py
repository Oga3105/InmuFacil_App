
import sys
import os
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

# Add project root to sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

from backend.src.config.database import engine
from backend.src.models.base import Base
from backend.src.models.notaries import Notary

# Note: We must ensure enum types are created if they don't exist
# But SQLAlchemy create_all handles tables. 
# For columns added to existing tables, we might need manual ALTER if not using Alembic.
# Here we will try a mix: create new table, and use raw SQL for ALTER.

def migrate():
    print("Migrating Hito 14 Schema...")
    
    # 1. Create Notaries Table
    Base.metadata.create_all(bind=engine)
    print("✅ Created/Verified 'notaries' table.")

    # 2. Add Columns to 'offers' table
    # We use raw SQL because SQLAlchemy Base.metadata.create_all does NOT update existing tables.
    with engine.connect() as conn:
        conn = conn.execution_options(isolation_level="AUTOCOMMIT")
        
        # Add notary_id
        try:
            conn.execute(sa.text("ALTER TABLE offers ADD COLUMN notary_id INTEGER REFERENCES notaries(id)"))
            print("✅ Added 'notary_id' column.")
        except Exception as e:
            print(f"ℹ️ 'notary_id' column might already exist: {e}")

        # Add notary_appointment_date
        try:
            conn.execute(sa.text("ALTER TABLE offers ADD COLUMN notary_appointment_date TIMESTAMP WITH TIME ZONE"))
            print("✅ Added 'notary_appointment_date' column.")
        except Exception as e:
            print(f"ℹ️ 'notary_appointment_date' column might already exist: {e}")

        # Add notary_status Enum
        # First ensure type exists (Postgres specific if not using verify)
        # But we defined it as Enum in SQLAlchemy. 
        # Let's add the column as VARCHAR first to be safe or use text
        try:
             conn.execute(sa.text("ALTER TABLE offers ADD COLUMN notary_status VARCHAR DEFAULT 'not_assigned'"))
             print("✅ Added 'notary_status' column.")
        except Exception as e:
            print(f"ℹ️ 'notary_status' column might already exist: {e}")

if __name__ == "__main__":
    migrate()
