"""
Migration: add V2 arras interview columns (separate buyer/seller interviews + AI contract).
Idempotent — safe to run multiple times.
Run with:
  docker exec inmufacil_backend python backend/scripts/add_arras_interview_v2.py
"""
import os
import sys

sys.path.insert(0, "/app")

import psycopg2

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://inmufacil_user:passwordSeguro123@db:5432/inmufacil_db",
)
dsn = DATABASE_URL.replace("postgresql+psycopg2://", "postgresql://")

MIGRATIONS = [
    ("buyer_answers_json",           "ALTER TABLE arras_interviews ADD COLUMN buyer_answers_json JSONB"),
    ("seller_answers_json",          "ALTER TABLE arras_interviews ADD COLUMN seller_answers_json JSONB"),
    ("buyer_interview_confirmed",    "ALTER TABLE arras_interviews ADD COLUMN buyer_interview_confirmed BOOLEAN NOT NULL DEFAULT FALSE"),
    ("seller_interview_confirmed",   "ALTER TABLE arras_interviews ADD COLUMN seller_interview_confirmed BOOLEAN NOT NULL DEFAULT FALSE"),
    ("contract_text",                "ALTER TABLE arras_interviews ADD COLUMN contract_text TEXT"),
    ("contract_status",              "ALTER TABLE arras_interviews ADD COLUMN contract_status VARCHAR(30)"),
    ("generation_count",             "ALTER TABLE arras_interviews ADD COLUMN generation_count INTEGER NOT NULL DEFAULT 0"),
    ("buyer_contract_accepted",      "ALTER TABLE arras_interviews ADD COLUMN buyer_contract_accepted BOOLEAN NOT NULL DEFAULT FALSE"),
    ("buyer_contract_accepted_at",   "ALTER TABLE arras_interviews ADD COLUMN buyer_contract_accepted_at TIMESTAMPTZ"),
    ("seller_contract_accepted",     "ALTER TABLE arras_interviews ADD COLUMN seller_contract_accepted BOOLEAN NOT NULL DEFAULT FALSE"),
    ("seller_contract_accepted_at",  "ALTER TABLE arras_interviews ADD COLUMN seller_contract_accepted_at TIMESTAMPTZ"),
    ("buyer_rejection_notes",        "ALTER TABLE arras_interviews ADD COLUMN buyer_rejection_notes TEXT"),
    ("seller_rejection_notes",       "ALTER TABLE arras_interviews ADD COLUMN seller_rejection_notes TEXT"),
    ("seller_iban_enc",              "ALTER TABLE arras_interviews ADD COLUMN seller_iban_enc VARCHAR"),
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
            WHERE table_name = 'arras_interviews' AND column_name = %s
            """,
            (col_name,),
        )
        if cur.fetchone():
            print(f"  skip: '{col_name}' already exists")
        else:
            cur.execute(ddl)
            added.append(col_name)
            print(f"  added: '{col_name}'")

    cur.close()
    conn.close()

    if added:
        print(f"Migration OK: added {added}")
    else:
        print("Migration OK: nothing to do")


if __name__ == "__main__":
    run()
