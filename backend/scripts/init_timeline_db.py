import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent.parent))

from backend.src.config.database import engine
from backend.src.models.base import Base
from backend.src.models import timeline # Import to register models

def init_db():
    print("Initializing Database Schema for Timeline Module...")
    # This will create tables if they don't exist
    Base.metadata.create_all(bind=engine)
    print("Database schema updated successfully.")

if __name__ == "__main__":
    init_db()
