from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
from backend.core.logging_config import get_logger

# 1. Load Environment Variables
load_dotenv()

# 2. Get Database URL
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sql_app.db")

# 3. Setup logging
logger = get_logger(__name__)

# 4. Configure Engine
if "sqlite" in SQLALCHEMY_DATABASE_URL:
    logger.warning(f"DATABASE MODE: SQLite Local ({SQLALCHEMY_DATABASE_URL})")
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )
else:
    logger.info(f"DATABASE MODE: PostgreSQL ({SQLALCHEMY_DATABASE_URL})")
    engine = create_engine(SQLALCHEMY_DATABASE_URL)

# 4. Configurations Session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 5. Dependency Injection
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
