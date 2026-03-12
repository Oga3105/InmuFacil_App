-- ============================================================================
-- DNI Uniqueness via HMAC
-- Descripcion: Columna dni_hmac para garantizar que un DNI/NIE/Pasaporte
--              no pueda estar vinculado a mas de una cuenta de usuario.
--              Usa HMAC-SHA256 (no reversible) para GDPR compliance.
-- Fecha:       2026-03-12
-- @Shield:     HMAC anonimizado — no permite recuperar el DNI original
-- @Architect:  UNIQUE WHERE NOT NULL — retrocompatible con usuarios existentes
-- ============================================================================

-- 1. Añadir columna
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS dni_hmac VARCHAR(64);

-- 2. Indice unico parcial: solo sobre valores no-NULL (retrocompatible)
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_dni_hmac
    ON users (dni_hmac)
    WHERE dni_hmac IS NOT NULL;

-- 3. Verificacion
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'dni_hmac'
    ) THEN
        RAISE NOTICE 'DNI HMAC Migration OK: columna dni_hmac creada con indice unico parcial.';
    END IF;
END;
$$;
