"""
Migration: add second_buyer_status and second_buyer_rejection_reason
to the buyer_solvency table (PostgreSQL).
Safe to run multiple times (idempotent).
"""
import os
import logging
from sqlalchemy import create_engine, text

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

DB_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://inmufacil_user:passwordSeguro123@localhost:5432/inmufacil_db",
)


def column_exists(conn, table: str, column: str) -> bool:
    result = conn.execute(
        text(
            "SELECT COUNT(*) FROM information_schema.columns "
            "WHERE table_name = :t AND column_name = :c"
        ),
        {"t": table, "c": column},
    )
    return result.scalar() > 0


def migrate():
    engine = create_engine(DB_URL)
    with engine.connect() as conn:
        added = []

        if not column_exists(conn, "buyer_solvency", "second_buyer_status"):
            conn.execute(
                text("ALTER TABLE buyer_solvency ADD COLUMN second_buyer_status VARCHAR(20)")
            )
            added.append("second_buyer_status")

        if not column_exists(conn, "buyer_solvency", "second_buyer_rejection_reason"):
            conn.execute(
                text("ALTER TABLE buyer_solvency ADD COLUMN second_buyer_rejection_reason TEXT")
            )
            added.append("second_buyer_rejection_reason")

        conn.commit()

    if added:
        logger.info("Migration OK: added columns %s to buyer_solvency", added)
    else:
        logger.info("Migration: columns already exist, nothing to do.")


if __name__ == "__main__":
    migrate()
