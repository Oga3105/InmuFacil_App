# Secrets Management

Tratamiento de variables de entorno y credenciales corporativas (Sin revelar secretos reales en este documento o en el código).

## Backend `.env`
- `DATABASE_URL`: Cadena de conexión de PostgreSQL (ej: `postgresql://user:pass@localhost:5432/db`).
- `JWT_SECRET_KEY`: Llave de alta entropía requerida para la firma de tokens (HS256).
- `CRYPTO_FERNET_KEY`: Clave para cifrar y descifrar conversaciones seguras at-rest.
- `SMTP_PASSWORD` (Opcional): Contraseña para proveedor de email si no se usa el MockProvider.

## Frontend `.env` / `config.json`
- `API_BASE_URL`: URL base apuntando a localhost en la etapa de desarrollo, o a la URL gestionada por Cloudflare en Producción.

> **Aviso de Seguridad de @Shield**: Bajo ningún concepto se subirá un archivo `.env` completo o una credencial *hardcodeada* al repositorio de control de versiones. Todo secret real reside en el inyector de CI/CD o manualmente en el VPS.
