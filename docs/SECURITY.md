# Security Policies

Política integral auditada e implementada bajo las directrices del rol **@Shield**.

## Prevención OWASP (Top 4 en el proyecto)
1. **Inyección SQL**: Mitigada estructuralmente mediante el uso del ORM SQLAlchemy y Prepared Statements.
2. **Autenticación Rota**: Implementada vía JWT con caducidad definida (Exp) y almacenamiento del token exclusivamente en the *SecureStorage* disponible en Flutter (no `SharedPreferences` para el token).
3. **Exposición de Datos Sensibles**: Redacción dinámica (Tachado en imágenes) de Identificaciones y encriptado At-Rest para las conversaciones usando Fernet.
4. **Control de Acceso Inseguro (IDOR)**: Verificaciones estrictas en los endpoints; un usuario nunca debe poder iterar objetos que no le pertenezcan (`user.id == owner_id`).

## Headers de Seguridad y Protección de Red
- FastAPI integra el `CORSMiddleware`.
- **CORS Configurado**: Estrictamente limitado a `http://localhost:8001`, `http://127.0.0.1:8001`, y los dominios formales de producción. El comodín `*` está estrictamente prohibido post-lanzamiento.
- HSTS manejado pasivamente a nivel de CDN en Cloudflare.
