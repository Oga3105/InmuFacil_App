-- Migration: add_ai_usage_log
-- Date: 2026-04-10
-- Author: @Shield + @Architect
-- Purpose: Server-side AI rate limiting per authenticated user.
--          Registers every AI endpoint call for 24h rolling window checks.
--          No PII / no call content stored — RGPD-safe.

CREATE TABLE IF NOT EXISTS ai_usage_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature     VARCHAR(50) NOT NULL,
    called_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    ip_address  VARCHAR(45)
);

-- Composite index used by the rate-check query:
-- SELECT COUNT(*) FROM ai_usage_log
-- WHERE user_id = $1 AND feature = $2 AND called_at > NOW() - INTERVAL '24 hours'
CREATE INDEX IF NOT EXISTS ix_ai_usage_log_user_feature_date
    ON ai_usage_log (user_id, feature, called_at);
