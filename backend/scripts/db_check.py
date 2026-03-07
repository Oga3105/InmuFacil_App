"""
Diagnostic script: direct SQLite inspection of offers and messages tables.
Usage:
    DB_PATH=inmufacil.db python backend/scripts/db_check.py
"""
import os
import sqlite3

DB_PATH = os.environ.get("DB_PATH", "inmufacil.db")

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

print("--- OFFERS (offers table) ---")
try:
    cursor.execute("SELECT id, status, amount, buyer_id, property_id FROM offers")
    for row in cursor.fetchall():
        print(row)
except Exception as e:
    print(f"Error: {e}")

print("\n--- MESSAGES (offer_messages table) ---")
try:
    cursor.execute(
        "SELECT id, offer_id, message_type, action_data, is_read, sender_id "
        "FROM offer_messages"
    )
    for row in cursor.fetchall():
        print(row)
except Exception as e:
    print(f"Error: {e}")

conn.close()
