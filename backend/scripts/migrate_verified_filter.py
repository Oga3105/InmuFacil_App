
import sqlite3
import os

def migrate():
    db_path = "inmufacil.db"
    if not os.path.exists(db_path):
        print(f"Error: Database {db_path} not found.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Add is_verified column
        print("Adding is_verified column to properties table...")
        cursor.execute("ALTER TABLE properties ADD COLUMN is_verified BOOLEAN DEFAULT 1")
        
        # Update two properties to be unverified (id=1 and id=2 for example)
        print("Updating sample properties (id=1, id=2) to NOT BE VERIFIED...")
        cursor.execute("UPDATE properties SET is_verified = 0 WHERE id IN (1, 2)")
        
        conn.commit()
        print("Migration successful!")
    except sqlite3.OperationalError as e:
        if "duplicate column name: is_verified" in str(e).lower():
            print("is_verified column already exists.")
        else:
            print(f"Operational error: {e}")
    except Exception as e:
        print(f"Error during migration: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
