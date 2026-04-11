-- Migration: Add price history columns to properties table
-- Enables price reduction display (previous price + discount badge).
-- Run once against your PostgreSQL database.

ALTER TABLE properties ADD COLUMN IF NOT EXISTS previous_price FLOAT;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS price_updated_at TIMESTAMPTZ;
