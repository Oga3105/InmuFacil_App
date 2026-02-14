
from sqlalchemy import create_engine, text
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Database URL (Assuming SQLITE in root or relative to script execution)
# You seem to be running from root `InmuFacil_Project`
DB_URL = "sqlite:///./inmufacil.db"

def migrate():
    engine = create_engine(DB_URL)
    with engine.connect() as conn:
        try:
            logger.info("Checking if 'contract_data' column exists in 'offers' table...")
            # Check if column exists (Specific to SQLite pragma)
            result = conn.execute(text("PRAGMA table_info(offers)"))
            columns = [row[1] for row in result.fetchall()]
            
            if "contract_data" not in columns:
                logger.info("Adding 'contract_data' column...")
                conn.execute(text("ALTER TABLE offers ADD COLUMN contract_data JSON DEFAULT NULL"))
                conn.commit()
                logger.info("Migration successful: Added 'contract_data'.")
            else:
                logger.info("Column 'contract_data' already exists. No action needed.")
                
        except Exception as e:
            logger.error(f"Error during migration: {e}")

if __name__ == "__main__":
    migrate()
