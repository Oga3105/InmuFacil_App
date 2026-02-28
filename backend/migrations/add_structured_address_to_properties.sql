-- Migration: Add structured address columns to properties table
-- Run once against your PostgreSQL database.

ALTER TABLE properties ADD COLUMN IF NOT EXISTS street VARCHAR;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS street_number VARCHAR;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS floor VARCHAR;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS city VARCHAR;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS province VARCHAR;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS postal_code VARCHAR;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS latitude FLOAT;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS longitude FLOAT;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS hide_exact_location BOOLEAN DEFAULT FALSE;

-- Make location nullable (was NOT NULL before)
ALTER TABLE properties ALTER COLUMN location DROP NOT NULL;
