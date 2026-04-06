-- Migration: Add AI Comfort Index columns to properties table
-- Run once on the production database

ALTER TABLE properties
  ADD COLUMN IF NOT EXISTS ai_comfort_consent BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS ai_comfort_consent_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ai_comfort_data_cache TEXT,
  ADD COLUMN IF NOT EXISTS ai_comfort_cache_expires_at TIMESTAMPTZ;

-- Verify
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'properties'
  AND column_name LIKE 'ai_comfort%'
ORDER BY column_name;
