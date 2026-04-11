"""
Migration: add email_notifications_enabled to users table.

Adds a boolean column that allows users to opt out of email notifications
triggered by other users' actions (offer received, comfort request, etc.).
Own-action confirmation emails are always sent regardless of this flag.

Default: TRUE (opt-out model, GDPR-compliant for transactional platform emails).
"""

import os
import sys
from sqlalchemy import create_engine, text

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/inmufacil_db",
)


def migrate() -> None:
    engine = create_engine(DATABASE_URL)

    add_column_sql = """
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS email_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE;
    """

    try:
        with engine.connect() as conn:
            print("RUNNING: Adding email_notifications_enabled to users...")
            conn.execute(text(add_column_sql))
            conn.commit()
            print("OK: Column email_notifications_enabled added (or already exists).")
    except Exception as exc:
        print(f"ERROR: {exc}")
        sys.exit(1)


if __name__ == "__main__":
    migrate()
