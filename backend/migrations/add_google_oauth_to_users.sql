-- ============================================================================
-- Google OAuth — Soporte de registro e inicio de sesion con Google
-- Descripcion: hashed_password nullable + columna google_id en users
-- Fecha:       2026-03-21
-- @Shield:     google_id almacenado en claro (identificador publico de Google,
--              no es secreto). hashed_password NULL solo para cuentas Google-only.
-- @Architect:  Backwards-compatible: usuarios existentes no se ven afectados.
-- ============================================================================

-- 1. Hacer hashed_password nullable (usuarios Google no tienen contrasena local)
ALTER TABLE users
    ALTER COLUMN hashed_password DROP NOT NULL;

-- 2. Agregar columna google_id para vincular cuentas Google
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS google_id VARCHAR(128) UNIQUE;

-- 3. Indice para busqueda rapida por google_id
CREATE INDEX IF NOT EXISTS idx_users_google_id
    ON users (google_id)
    WHERE google_id IS NOT NULL;

-- 4. Verificacion
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'google_id'
    ) THEN
        RAISE NOTICE 'Google OAuth Migration OK: columna google_id creada en users.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'hashed_password'
          AND is_nullable = 'YES'
    ) THEN
        RAISE NOTICE 'Google OAuth Migration OK: hashed_password ahora es nullable.';
    END IF;
END;
$$;
