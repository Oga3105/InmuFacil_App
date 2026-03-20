-- Migration: add_ai_consent_log
-- Description: Tabla de registro de consentimientos explícitos para uso de IA.
--              Base jurídica: Art. 6.1.a RGPD / Art. 7 LOPDGDD.
--              Los registros son inmutables (accountability Art. 5.2 RGPD).
-- Date: 2026-03-20

CREATE TABLE IF NOT EXISTS ai_consent_logs (
    id                   SERIAL PRIMARY KEY,
    user_id              INTEGER NOT NULL REFERENCES users(id),
    action_type          VARCHAR(100) NOT NULL,
    action_label         VARCHAR(255) NOT NULL,
    data_categories      TEXT NOT NULL,          -- JSON array as text
    purpose              TEXT NOT NULL,
    ai_provider          VARCHAR(255) NOT NULL,
    consent_text_version VARCHAR(50) NOT NULL DEFAULT 'v1.0',
    consented_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address           VARCHAR(45),
    user_agent           VARCHAR(512),
    property_id          VARCHAR(50)
);

-- Index para consultas frecuentes: historial por usuario
CREATE INDEX IF NOT EXISTS idx_ai_consent_logs_user_id
    ON ai_consent_logs(user_id);

-- Index para auditoria: busqueda por accion y fecha
CREATE INDEX IF NOT EXISTS idx_ai_consent_logs_action_type_date
    ON ai_consent_logs(action_type, consented_at);
