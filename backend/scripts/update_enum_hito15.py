import sys
from pathlib import Path
from sqlalchemy import text
sys.path.append(str(Path(__file__).parent.parent.parent))

from backend.src.config.database import engine

def migrate():
    print("Migrating Enums for Hito 15...")
    with engine.connect() as conn:
        # Prevent transaction block error with autocommit
        conn = conn.execution_options(isolation_level="AUTOCOMMIT")
        
        try:
            print("Adding 'completed' to offerstatus...")
            conn.execute(text("ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'completed'"))
        except Exception as e:
            print(f"OfferStatus Warning: {e}")

        try:
            print("Adding 'sold' to propertystatus...")
            conn.execute(text("ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'sold'"))
        except Exception as e:
            print(f"PropertyStatus Warning: {e}")
            
    print("Migration finished.")

if __name__ == "__main__":
    migrate()
