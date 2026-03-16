"""
Migration: add buyer_equity_json and seller_equity_json to arras_interviews.
Sprint V26 — Arras Equity Analyzer.
Idempotent: safe to run multiple times.
"""
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from backend.src.config.database import engine

COLUMNS = [
    ("buyer_equity_json", "JSONB"),
    ("seller_equity_json", "JSONB"),
]

with engine.connect() as conn:
    for col_name, col_type in COLUMNS:
        exists = conn.execute(
            __import__("sqlalchemy").text(
                "SELECT 1 FROM information_schema.columns "
                "WHERE table_name = 'arras_interviews' AND column_name = :col"
            ),
            {"col": col_name},
        ).fetchone()
        if not exists:
            conn.execute(
                __import__("sqlalchemy").text(
                    f"ALTER TABLE arras_interviews ADD COLUMN {col_name} {col_type}"
                )
            )
            print(f"[OK] Added column: {col_name} ({col_type})")
        else:
            print(f"[SKIP] Column already exists: {col_name}")
    conn.commit()

print("Migration complete.")
