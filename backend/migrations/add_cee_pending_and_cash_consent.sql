-- Migration: add CEE_PENDING offer status and buyer cash consent tracking
-- Sprint: V27

BEGIN;

-- 1. Add cee_pending to offerstatus enum (safe: IF NOT EXISTS via DO block)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'cee_pending'
          AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offerstatus')
    ) THEN
        ALTER TYPE offerstatus ADD VALUE 'cee_pending' BEFORE 'pending';
    END IF;
END;
$$;

-- 2. Add buyer_cash_consent_at to arras_interviews
ALTER TABLE arras_interviews
    ADD COLUMN IF NOT EXISTS buyer_cash_consent_at TIMESTAMPTZ;

COMMIT;
