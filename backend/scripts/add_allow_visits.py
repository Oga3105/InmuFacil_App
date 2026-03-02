"""
Migration: add allow_visits column to properties table.
Run once against an existing database: python -m backend.scripts.add_allow_visits
"""
import sys
import os
import sqlalchemy as sa

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

from backend.src.config.database import engine


def migrate():
    print("Migration: add allow_visits to properties...")
    with engine.connect() as conn:
        conn = conn.execution_options(isolation_level="AUTOCOMMIT")
        try:
            conn.execute(sa.text(
                "ALTER TABLE properties ADD COLUMN allow_visits BOOLEAN NOT NULL DEFAULT TRUE"
            ))
            print("allow_visits column added.")
        except Exception as e:
            print(f"Column may already exist (safe to ignore): {e}")


if __name__ == "__main__":
    migrate()
