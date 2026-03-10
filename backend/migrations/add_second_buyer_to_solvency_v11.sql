-- Migration V11: Second buyer identity fields on buyer_solvency
-- Added encrypted PII columns for a joint buyer's identity verification.
-- These are populated via POST /solvency/second-buyer (separate from the primary wizard).
-- All fields are AES-256-GCM encrypted at rest (same key as other PII).
-- 2026-03-10

ALTER TABLE buyer_solvency
  ADD COLUMN IF NOT EXISTS second_buyer_name_enc       TEXT,
  ADD COLUMN IF NOT EXISTS second_buyer_dni_enc        TEXT,
  ADD COLUMN IF NOT EXISTS second_buyer_email_enc      TEXT,
  ADD COLUMN IF NOT EXISTS second_buyer_verified_at    TIMESTAMPTZ;

COMMENT ON COLUMN buyer_solvency.second_buyer_name_enc  IS 'AES-256-GCM encrypted full name of the second buyer (GDPR PII)';
COMMENT ON COLUMN buyer_solvency.second_buyer_dni_enc   IS 'AES-256-GCM encrypted DNI/NIE of the second buyer (GDPR PII)';
COMMENT ON COLUMN buyer_solvency.second_buyer_email_enc IS 'AES-256-GCM encrypted email of the second buyer (GDPR PII)';
COMMENT ON COLUMN buyer_solvency.second_buyer_verified_at IS 'Timestamp when the second buyer completed identity verification';
