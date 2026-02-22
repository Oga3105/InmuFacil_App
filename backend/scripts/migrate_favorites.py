import sys
import os
from sqlalchemy import create_engine, text

# Database URL
DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/inmufacil_db"

def migrate():
    engine = create_engine(DATABASE_URL)
    
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS property_favorites (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT _user_property_favorite_uc UNIQUE (user_id, property_id)
    );
    """
    
    try:
        with engine.connect() as conn:
            print("RUNNING: Create table property_favorites...")
            conn.execute(text(create_table_sql))
            conn.commit()
            print("OK: Table created or already exists.")
    except Exception as e:
        print(f"ERROR: {str(e)}")

if __name__ == "__main__":
    migrate()
