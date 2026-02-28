-- Migration: add extra amenity columns to property_features
-- These columns were present in the frontend wizard but missing from the DB schema.

ALTER TABLE property_features ADD COLUMN IF NOT EXISTS has_garage BOOLEAN DEFAULT FALSE;
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS has_storage BOOLEAN DEFAULT FALSE;
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS has_wardrobes BOOLEAN DEFAULT FALSE;
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS has_exterior BOOLEAN DEFAULT FALSE;
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS has_accessibility BOOLEAN DEFAULT FALSE;
