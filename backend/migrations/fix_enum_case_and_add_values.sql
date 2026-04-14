-- Migration: Fix enum case mismatch and add missing values
-- Fixes two scenarios:
--   1. DBs created via create_all (lowercase) missing 'draft','exposed','unpublished'
--   2. DBs created from SQL scripts (UPPERCASE) needing lowercase variants
--
-- IMPORTANT: ALTER TYPE ADD VALUE cannot run inside a transaction.
--            Run this file with psql using \i or pg_dump --no-acl.
--            Each ALTER TYPE statement commits automatically in psql.
--
-- Run once. All statements are idempotent.

-- ============================================================================
-- Step 1: Add missing lowercase enum values
-- ============================================================================

ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'draft';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'exposed';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'published';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'unpublished';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'reserved';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'sold';

ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'piso';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'atico';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'duplex';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'chalet';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'casa_rustica';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'casa_singular';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'local';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'oficina';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'nave';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'edificio';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'garaje';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'terreno';
ALTER TYPE propertytype ADD VALUE IF NOT EXISTS 'finca_rustica';

ALTER TYPE operationtype ADD VALUE IF NOT EXISTS 'venta';
ALTER TYPE operationtype ADD VALUE IF NOT EXISTS 'alquiler';
ALTER TYPE operationtype ADD VALUE IF NOT EXISTS 'btr';
ALTER TYPE operationtype ADD VALUE IF NOT EXISTS 'inversion';

-- ============================================================================
-- Step 2: Add missing columns (safe - IF NOT EXISTS)
-- ============================================================================

ALTER TABLE properties ADD COLUMN IF NOT EXISTS previous_price FLOAT;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS price_updated_at TIMESTAMPTZ;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS ai_comfort_consent BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS ai_comfort_consent_date TIMESTAMPTZ;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS ai_comfort_data_cache TEXT;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS ai_comfort_cache_expires_at TIMESTAMPTZ;

-- Make location nullable (was NOT NULL in legacy schema)
ALTER TABLE properties ALTER COLUMN location DROP NOT NULL;

-- ============================================================================
-- Step 3: Normalise UPPERCASE data to lowercase
-- (Only affects rows whose values are all-uppercase, e.g. 'PUBLISHED')
-- ============================================================================

UPDATE properties
   SET status = LOWER(status::text)::propertystatus
 WHERE status IS NOT NULL
   AND status::text ~ '^[A-Z_]+$';

UPDATE properties
   SET property_type = LOWER(property_type::text)::propertytype
 WHERE property_type IS NOT NULL
   AND property_type::text ~ '^[A-Z_]+$';

UPDATE properties
   SET operation_type = LOWER(operation_type::text)::operationtype
 WHERE operation_type IS NOT NULL
   AND operation_type::text ~ '^[A-Z_]+$';

-- ============================================================================
-- Verify
-- ============================================================================

SELECT enumlabel FROM pg_enum
  JOIN pg_type ON pg_enum.enumtypid = pg_type.oid
 WHERE pg_type.typname = 'propertystatus'
 ORDER BY enumsortorder;
