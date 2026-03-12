-- ============================================================================
-- V17: Notification Center & Push Notifications
-- Descripcion: Tabla de historial de notificaciones + token FCM en users
-- Fecha:       2026-03-12
-- @Architect:  Deduplicacion via UNIQUE(user_id, offer_id, urgency_type)
-- @Shield:     CASCADE DELETE al borrar usuario (GDPR - Derecho al Olvido)
-- ============================================================================

-- 1. Columna fcm_token en users
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(512);

-- 2. Tabla notification_logs
CREATE TABLE IF NOT EXISTS notification_logs (
    id                  SERIAL PRIMARY KEY,
    user_id             INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title               VARCHAR(255) NOT NULL,
    body                VARCHAR(1000) NOT NULL,
    notification_type   VARCHAR(32) NOT NULL DEFAULT 'urgency',
    is_read             BOOLEAN NOT NULL DEFAULT FALSE,
    deep_link           VARCHAR(512),
    offer_id            INTEGER REFERENCES offers(id) ON DELETE SET NULL,
    urgency_type        VARCHAR(64),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_at             TIMESTAMPTZ,

    CONSTRAINT uq_notification_user_offer_type
        UNIQUE (user_id, offer_id, urgency_type)
);

-- 3. Indices de rendimiento
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id
    ON notification_logs (user_id);

CREATE INDEX IF NOT EXISTS idx_notification_logs_user_unread
    ON notification_logs (user_id, is_read)
    WHERE is_read = FALSE;

-- 4. Verificacion
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notification_logs') THEN
        RAISE NOTICE 'V17 Migration OK: notification_logs tabla creada.';
    END IF;
END;
$$;
