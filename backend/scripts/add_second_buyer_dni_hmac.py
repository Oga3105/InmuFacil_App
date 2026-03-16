"""
Migration: add second_buyer_dni_hmac column to buyer_solvency table.

Idempotent — safe to run multiple times.
Run with:
  docker exec inmufacil_backend python backend/scripts/add_second_buyer_dni_hmac.py
"""
import os
import sys

sys.path.insert(0, "/app")

import psycopg2

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://inmufacil_user:passwordSeguro123@db:5432/inmufacil_db",
)

# Strip SQLAlchemy dialect prefix for psycopg2
dsn = DATABASE_URL.replace("postgresql+psycopg2://", "postgresql://")

MIGRATIONS = [
    (
        "second_buyer_dni_hmac",
        "ALTER TABLE buyer_solvency ADD COLUMN second_buyer_dni_hmac VARCHAR(64)",
    ),
]


def run():
    conn = psycopg2.connect(dsn)
    conn.autocommit = True
    cur = conn.cursor()

    added = []
    for col_name, ddl in MIGRATIONS:
        cur.execute(
            """
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'buyer_solvency' AND column_name = %s
            """,
            (col_name,),
        )
        if cur.fetchone():
            print(f"  skip: column '{col_name}' already exists")
        else:
            cur.execute(ddl)
            added.append(col_name)
            print(f"  added: column '{col_name}'")

    cur.close()
    conn.close()

    if added:
        print(f"Migration OK: added columns {added}")
    else:
        print("Migration OK: nothing to do")


if __name__ == "__main__":
    run()
