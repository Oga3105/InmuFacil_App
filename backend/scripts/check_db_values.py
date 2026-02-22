from sqlalchemy import create_engine, text
import os

# Using direct URL
DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/inmufacil_db"

def check_db():
    print(f"Connecting to DB...")
    engine = create_engine(DATABASE_URL)
    
    try:
        with engine.connect() as conn:
            # Check properties table
            print("\n--- Properties Table (property_type column) ---")
            result = conn.execute(text("SELECT id, title, property_type FROM properties LIMIT 5"))
            rows = result.fetchall()
            for row in rows:
                print(f"ID: {row[0]}, Title: {row[1]}, Type: {row[2]} (Type: {type(row[2])})")
                
            # Check property_features table (floor column)
            print("\n--- Property Features Table (floor column) ---")
            result = conn.execute(text("SELECT property_id, floor FROM property_features LIMIT 5"))
            rows = result.fetchall()
            for row in rows:
                print(f"PropID: {row[0]}, Floor: {row[1]} (Type: {type(row[1])})")

    except Exception as e:
        print(f"Error: {repr(e)}")

if __name__ == "__main__":
    check_db()
