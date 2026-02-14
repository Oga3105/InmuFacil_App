import sys
import os
import logging
from sqlalchemy import create_engine, text

# Setup basic logging (ASCII only)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Direct DB URL for script execution
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/inmufacil_db"

def update_enum_types():
    try:
        # Use autocommit to allow ALTER TYPE commands which cannot run inside a transaction block
        engine = create_engine(SQLALCHEMY_DATABASE_URL, isolation_level="AUTOCOMMIT")
        
        # New types to add based on architectural debate
        new_types = [
            'atico', 
            'duplex', 
            'garaje', 
            'casa_rustica', 
            'casa_singular', 
            'finca_rustica', 
            'nave'
        ]
        
        logger.info("Starting PropertyType Enum Migration...")
        
        with engine.connect() as connection:
            for type_val in new_types:
                try:
                    # Postgres 12+ supports IF NOT EXISTS
                    # For older versions, we catch the DuplicateObject error
                    sql = text(f"ALTER TYPE propertytype ADD VALUE IF NOT EXISTS '{type_val}'")
                    logger.info(f"Adding type: {type_val}")
                    connection.execute(sql)
                    logger.info(f"Added {type_val}")
                except Exception as e:
                    # Check if it's "already exists" error
                    if "already exists" in str(e):
                        logger.info(f"Type {type_val} already exists.")
                    else:
                        logger.warning(f"Could not add {type_val}: {e}")
        
        logger.info("Helper migration complete! You can now update the Python Enum definitions.")
        
    except Exception as e:
        logger.error(f"Migration failed: {e}")

if __name__ == "__main__":
    update_enum_types()
