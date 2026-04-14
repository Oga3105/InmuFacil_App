-- Migration: Fix enum case mismatch and add missing values (ALL tables)
-- Fixes DBs created from SQL scripts (UPPERCASE enum values) so SQLAlchemy
-- Python enums (lowercase) can deserialize every row without ValueError.
--
-- IMPORTANT: ALTER TYPE ADD VALUE cannot run inside a transaction.
--            Run this file with psql using \i or pg_dump --no-acl.
--            Each ALTER TYPE statement commits automatically in psql.
--
-- Run once. All statements are idempotent.

-- ============================================================================
-- Step 1: Add missing lowercase enum values (AUTOCOMMIT required)
-- ============================================================================

-- propertystatus
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'draft';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'exposed';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'published';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'unpublished';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'reserved';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'sold';

-- propertytype
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

-- operationtype
ALTER TYPE operationtype ADD VALUE IF NOT EXISTS 'venta';
ALTER TYPE operationtype ADD VALUE IF NOT EXISTS 'alquiler';
ALTER TYPE operationtype ADD VALUE IF NOT EXISTS 'btr';
ALTER TYPE operationtype ADD VALUE IF NOT EXISTS 'inversion';

-- orientation (property_features)
ALTER TYPE orientation ADD VALUE IF NOT EXISTS 'norte';
ALTER TYPE orientation ADD VALUE IF NOT EXISTS 'sur';
ALTER TYPE orientation ADD VALUE IF NOT EXISTS 'este';
ALTER TYPE orientation ADD VALUE IF NOT EXISTS 'oeste';
ALTER TYPE orientation ADD VALUE IF NOT EXISTS 'noreste';
ALTER TYPE orientation ADD VALUE IF NOT EXISTS 'noroeste';
ALTER TYPE orientation ADD VALUE IF NOT EXISTS 'sureste';
ALTER TYPE orientation ADD VALUE IF NOT EXISTS 'suroeste';

-- heatingtype (property_features)
ALTER TYPE heatingtype ADD VALUE IF NOT EXISTS 'gas_natural';
ALTER TYPE heatingtype ADD VALUE IF NOT EXISTS 'electrica';
ALTER TYPE heatingtype ADD VALUE IF NOT EXISTS 'central';
ALTER TYPE heatingtype ADD VALUE IF NOT EXISTS 'aerotermia';
ALTER TYPE heatingtype ADD VALUE IF NOT EXISTS 'otro';

-- conservationstate (property_features)
ALTER TYPE conservationstate ADD VALUE IF NOT EXISTS 'a_estrenar';
ALTER TYPE conservationstate ADD VALUE IF NOT EXISTS 'buen_estado';
ALTER TYPE conservationstate ADD VALUE IF NOT EXISTS 'a_reformar';

-- energycertification (property_legal)
-- NOTE: A, B, C, D, E, F, G intentionally stay uppercase — Python enum uses uppercase letters.
--       Only EN_TRAMITE and EXENTO need lowercase variants.
ALTER TYPE energycertification ADD VALUE IF NOT EXISTS 'en_tramite';
ALTER TYPE energycertification ADD VALUE IF NOT EXISTS 'exento';

-- itestatus (property_legal)
ALTER TYPE itestatus ADD VALUE IF NOT EXISTS 'pasada';
ALTER TYPE itestatus ADD VALUE IF NOT EXISTS 'pendiente';
ALTER TYPE itestatus ADD VALUE IF NOT EXISTS 'desfavorable';
ALTER TYPE itestatus ADD VALUE IF NOT EXISTS 'no_obligado';

-- notasimplestatus (property_legal)
ALTER TYPE notasimplestatus ADD VALUE IF NOT EXISTS 'pending';
ALTER TYPE notasimplestatus ADD VALUE IF NOT EXISTS 'verified';
ALTER TYPE notasimplestatus ADD VALUE IF NOT EXISTS 'rejected';

-- crimerate (property_environment)
ALTER TYPE crimerate ADD VALUE IF NOT EXISTS 'bajo';
ALTER TYPE crimerate ADD VALUE IF NOT EXISTS 'medio';
ALTER TYPE crimerate ADD VALUE IF NOT EXISTS 'alto';

-- mediatype (property_media)
ALTER TYPE mediatype ADD VALUE IF NOT EXISTS 'image';
ALTER TYPE mediatype ADD VALUE IF NOT EXISTS 'video';
ALTER TYPE mediatype ADD VALUE IF NOT EXISTS 'virtual_tour';

-- offerstatus (offers)
ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'pending';
ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'accepted';
ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'rejected';
ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'withdrawn';
ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'counter_offer';
ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'signing_pending';
ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'signed';
ALTER TYPE offerstatus ADD VALUE IF NOT EXISTS 'completed';

-- dnistatus (users)
ALTER TYPE dnistatus ADD VALUE IF NOT EXISTS 'sin_verificar';
ALTER TYPE dnistatus ADD VALUE IF NOT EXISTS 'pendiente';
ALTER TYPE dnistatus ADD VALUE IF NOT EXISTS 'validado';
ALTER TYPE dnistatus ADD VALUE IF NOT EXISTS 'rechazado';

-- usertype (users)
ALTER TYPE usertype ADD VALUE IF NOT EXISTS 'particular';
ALTER TYPE usertype ADD VALUE IF NOT EXISTS 'profesional';
ALTER TYPE usertype ADD VALUE IF NOT EXISTS 'financiero';
ALTER TYPE usertype ADD VALUE IF NOT EXISTS 'admin';
ALTER TYPE usertype ADD VALUE IF NOT EXISTS 'provider';

-- ============================================================================
-- Step 2: Add missing columns on properties (safe - IF NOT EXISTS)
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
-- Step 3: Normalise UPPERCASE data to lowercase in ALL tables
-- ============================================================================

-- properties
UPDATE properties SET status = LOWER(status::text)::propertystatus
 WHERE status IS NOT NULL AND status::text ~ '^[A-Z_]+$';

UPDATE properties SET property_type = LOWER(property_type::text)::propertytype
 WHERE property_type IS NOT NULL AND property_type::text ~ '^[A-Z_]+$';

UPDATE properties SET operation_type = LOWER(operation_type::text)::operationtype
 WHERE operation_type IS NOT NULL AND operation_type::text ~ '^[A-Z_]+$';

-- property_features
UPDATE property_features SET orientation = LOWER(orientation::text)::orientation
 WHERE orientation IS NOT NULL AND orientation::text ~ '^[A-Z_]+$';

UPDATE property_features SET heating_type = LOWER(heating_type::text)::heatingtype
 WHERE heating_type IS NOT NULL AND heating_type::text ~ '^[A-Z_]+$';

UPDATE property_features SET conservation_state = LOWER(conservation_state::text)::conservationstate
 WHERE conservation_state IS NOT NULL AND conservation_state::text ~ '^[A-Z_]+$';

-- property_legal
-- energycertification special case: only fix EN_TRAMITE and EXENTO, leave A-G untouched
UPDATE property_legal SET energy_certification = 'en_tramite'::energycertification
 WHERE energy_certification::text = 'EN_TRAMITE';

UPDATE property_legal SET energy_certification = 'exento'::energycertification
 WHERE energy_certification::text = 'EXENTO';

UPDATE property_legal SET ite_status = LOWER(ite_status::text)::itestatus
 WHERE ite_status IS NOT NULL AND ite_status::text ~ '^[A-Z_]+$';

UPDATE property_legal SET nota_simple_status = LOWER(nota_simple_status::text)::notasimplestatus
 WHERE nota_simple_status IS NOT NULL AND nota_simple_status::text ~ '^[A-Z_]+$';

-- property_environment
UPDATE property_environment SET crime_rate_level = LOWER(crime_rate_level::text)::crimerate
 WHERE crime_rate_level IS NOT NULL AND crime_rate_level::text ~ '^[A-Z_]+$';

-- property_media
UPDATE property_media SET media_type = LOWER(media_type::text)::mediatype
 WHERE media_type IS NOT NULL AND media_type::text ~ '^[A-Z_]+$';

-- offers
UPDATE offers SET status = LOWER(status::text)::offerstatus
 WHERE status IS NOT NULL AND status::text ~ '^[A-Z_]+$';

-- users
UPDATE users SET dni_status = LOWER(dni_status::text)::dnistatus
 WHERE dni_status IS NOT NULL AND dni_status::text ~ '^[A-Z_]+$';

UPDATE users SET user_type = LOWER(user_type::text)::usertype
 WHERE user_type IS NOT NULL AND user_type::text ~ '^[A-Z_]+$';

-- ============================================================================
-- Verify: check current enum values for key types
-- ============================================================================

SELECT 'propertystatus' AS type, enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE pg_type.typname = 'propertystatus' ORDER BY enumsortorder
UNION ALL
SELECT 'mediatype', enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE pg_type.typname = 'mediatype' ORDER BY enumsortorder
UNION ALL
SELECT 'offerstatus', enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE pg_type.typname = 'offerstatus' ORDER BY enumsortorder;
