"""
Migration: Add BYTEA storage columns to property_media and migrate existing files.

Phase 1 — Schema:
  ALTER TABLE property_media ADD COLUMN IF NOT EXISTS file_data BYTEA;
  ALTER TABLE property_media ADD COLUMN IF NOT EXISTS content_type VARCHAR(100);
  ALTER TABLE property_media ALTER COLUMN file_path DROP NOT NULL;

Phase 2 — Data:
  For every row where media_type = 'image' AND file_data IS NULL AND file_path IS NOT NULL:
    - Read the file from disk (relative to the project root).
    - Write the raw bytes into file_data.
    - Set content_type = 'image/jpeg'.
    - Set file_path = NULL.

Usage:
    python backend/scripts/migrate_media_bytea.py

Reads DATABASE_URL from the .env file at the project root.
"""

import mimetypes
import os
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Bootstrap: resolve project root and load .env
# ---------------------------------------------------------------------------
project_root = Path(__file__).resolve().parents[2]
env_file = project_root / ".env"

if env_file.exists():
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, value = line.partition("=")
            os.environ.setdefault(key.strip(), value.strip())

database_url = os.environ.get("DATABASE_URL")
if not database_url:
    print("ERROR: DATABASE_URL not set. Check your .env file.", file=sys.stderr)
    sys.exit(1)

try:
    import psycopg2
    from psycopg2 import Binary
except ImportError:
    print("ERROR: psycopg2 not installed. Run: pip install psycopg2-binary", file=sys.stderr)
    sys.exit(1)

# ---------------------------------------------------------------------------
# Phase 1 — DDL
# ---------------------------------------------------------------------------
DDL = [
    "ALTER TABLE property_media ADD COLUMN IF NOT EXISTS file_data BYTEA;",
    "ALTER TABLE property_media ADD COLUMN IF NOT EXISTS content_type VARCHAR(100);",
    "ALTER TABLE property_media ALTER COLUMN file_path DROP NOT NULL;",
]


def run_ddl(conn) -> None:
    with conn.cursor() as cur:
        for sql in DDL:
            print(f"  DDL: {sql}")
            cur.execute(sql)
    conn.commit()
    print("Phase 1 complete: schema updated.\n")


# ---------------------------------------------------------------------------
# Phase 2 — Data migration
# ---------------------------------------------------------------------------
SELECT_PENDING = """
    SELECT id, file_path
    FROM property_media
    WHERE media_type = 'image'
      AND file_data IS NULL
      AND file_path IS NOT NULL;
"""

UPDATE_ROW = """
    UPDATE property_media
    SET file_data    = %s,
        content_type = %s,
        file_path    = NULL
    WHERE id = %s;
"""


def _resolve_path(raw_path: str) -> Path:
    """
    file_path in the DB can be:
      - An absolute path  (e.g. /app/uploads/properties/3/abc.jpg)
      - A relative path   (e.g. uploads/properties/3/abc.jpg)
    Try absolute first; fall back to project_root-relative.
    """
    p = Path(raw_path)
    if p.is_absolute() and p.exists():
        return p
    candidate = project_root / raw_path.lstrip("/\\")
    if candidate.exists():
        return candidate
    raise FileNotFoundError(raw_path)


def run_data_migration(conn) -> None:
    with conn.cursor() as cur:
        cur.execute(SELECT_PENDING)
        rows = cur.fetchall()

    if not rows:
        print("Phase 2: no rows to migrate — all images already in DB.")
        return

    print(f"Phase 2: migrating {len(rows)} image(s) from disk to DB...\n")
    ok = skipped = 0

    for row_id, raw_path in rows:
        try:
            disk_path = _resolve_path(raw_path)
        except FileNotFoundError:
            print(f"  [SKIP] id={row_id} — file not found on disk: {raw_path}")
            skipped += 1
            continue

        file_bytes = disk_path.read_bytes()
        mime, _ = mimetypes.guess_type(str(disk_path))
        content_type = mime or "image/jpeg"

        with conn.cursor() as cur:
            cur.execute(UPDATE_ROW, (Binary(file_bytes), content_type, row_id))
        conn.commit()

        print(f"  [OK]   id={row_id}  {disk_path.name}  ({len(file_bytes):,} bytes)  {content_type}")
        ok += 1

    print(f"\nPhase 2 complete: {ok} migrated, {skipped} skipped (file missing).")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def main() -> None:
    print(f"Connecting to database...\n")
    try:
        conn = psycopg2.connect(database_url)
        conn.autocommit = False
    except Exception as exc:
        print(f"ERROR: Cannot connect to database: {exc}", file=sys.stderr)
        sys.exit(1)

    try:
        print("=== Phase 1: Schema migration ===")
        run_ddl(conn)

        print("=== Phase 2: Data migration (disk -> BYTEA) ===")
        run_data_migration(conn)
    except Exception as exc:
        conn.rollback()
        print(f"\nMigration FAILED — rolled back. Error: {exc}", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()

    print("\nAll done.")


if __name__ == "__main__":
    main()
