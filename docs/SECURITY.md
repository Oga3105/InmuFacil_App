# Security Policies

Politica integral auditada e implementada bajo las directrices del rol **@Shield**.
Compliance: GDPR, OWASP Top 10, PCI DSS (pagos), ISO 27001 (RBAC), MITRE ATT&CK.

---

## OWASP Top 10 — Mitigaciones

| OWASP | Riesgo | Mitigacion implementada |
|---|---|---|
| A01 | Control de acceso roto (IDOR) | `user.id == owner_id` verificado en cada endpoint. RBAC via `get_current_active_user` |
| A02 | Fallos criptograficos | AES-256-GCM para PII en reposo. JWT HS256 con expiracion. HTTPS forzado via Cloudflare |
| A03 | Inyeccion SQL | SQLAlchemy ORM + Prepared Statements. Ninguna query raw con input de usuario |
| A04 | Diseno inseguro | Rate limiting (contacto: 3/24h, AI: configurable). Anti-agency filter en registro |
| A05 | Mala configuracion de seguridad | CORS estrictamente limitado a dominios conocidos. Sin `*` en produccion |
| A06 | Componentes vulnerables | Dependabot activo para Python y Flutter. Actualizaciones semanales automatizadas |
| A07 | Autenticacion rota | JWT en `flutter_secure_storage` (nunca SharedPreferences). MFA por email en 2FA |
| A08 | Integridad de software | Pre-commit hooks para secretos. CodeQL en CI |
| A09 | Logging insuficiente | Audit logging de PII access. Logs de autenticacion y KYC |
| A10 | SSRF | Sin proxy de URLs externas. Gemini Vision procesa solo uploads internos |

---

## Autenticacion y Sesiones

- **JWT HS256** con expiracion configurable (`ACCESS_TOKEN_EXPIRE_MINUTES`)
- **MFA por email** (token 6 digitos, TTL 10 minutos) para login y reset de contrasena
- **Google OAuth** via Firebase Admin SDK — token verificado server-side, nunca client-trust
- **flutter_secure_storage** — JWT nunca en `SharedPreferences` ni `localStorage`
- **Refresh tokens** — implementados en `/auth/refresh`

---

## Cifrado de PII

- **Algoritmo:** AES-256-GCM via libreria `cryptography` (Python)
- **Clave maestra:** `INMUFACIL_MASTER_KEY` (env var, nunca en codigo)
- **Datos cifrados en reposo:** DNI/Pasaporte, foto de KYC, mensajes de chat
- **Datos redactados en imagenes:** Numeros de documento tachados en procesamiento Gemini Vision
- **Derecho al olvido (GDPR Art. 17):** Borrado seguro tecnica mente viable via endpoint DELETE `/users/me`

---

## Anti-Agency Filter

Tres capas de deteccion de agentes inmobiliarios profesionales intentando registrarse como particulares:

1. **Capa estatica:** Blacklist de dominios corporativos, keywords en nombre/empresa
2. **Capa IA/OSINT:** Gemini analiza perfil y detecta patrones profesionales
3. **Capa comunidad:** Sistema de reports (`POST /reports`) que alimenta el risk score

Umbral de riesgo configurable (`RISK_THRESHOLD`). Superado: cuenta bloqueada automaticamente.

---

## Active Intelligence Shield

- Investigacion OSINT automatica al superar umbral de riesgo
- Re-investigacion automatica si llegan nuevos reports sobre un usuario
- Alertas de moderacion a admin via email (`send_admin_moderation_alert`)

---

## Rate Limiting

| Endpoint | Limite | Ventana |
|---|---|---|
| `POST /contact/message` | 3 mensajes | 24 horas por usuario |
| `POST /ai/*` (generacion IA) | Configurable | Por usuario (in-memory) |
| `POST /auth/token` | Via Cloudflare | IP-based |

---

## Headers HTTP y Red

- **CORS:** `CORSMiddleware` — dominios permitidos: `localhost:8001`, `inmufacil.com`, `www.inmufacil.com`
- **HSTS:** Gestionado por Cloudflare (CDN nivel)
- **X-Frame-Options / CSP:** Configurados en Nginx (`docker-compose.prod.yml`)
- **TLS:** Certificado SSL/TLS via Cloudflare — solo HTTPS en produccion

---

## MITRE ATT&CK — Defensas Proactivas

| Tecnica | Defensa |
|---|---|
| T1110 Brute Force | Rate limiting Cloudflare + MFA obligatorio |
| T1566 Phishing | DKIM/SPF en dominio IONOS para emails salientes |
| T1078 Valid Accounts | Audit log de logins + deteccion de IPs anomalas (futuro) |
| T1190 Exploit Public-Facing App | CodeQL + Dependabot + OWASP mitigaciones |
| T1552 Credentials in Files | Pre-commit hook con deteccion de secretos (patrones API_KEY, SECRET, etc.) |

---

## Gestion de Secretos

- Todos los secretos en `.env` (nunca commiteados — `.gitignore`)
- Variables de entorno inyectadas via `env_file` en Docker Compose
- **Regla de restauracion obligatoria:** Si `.env` se modifica para un commit, backup previo (`cp .env .env.backup`) y restauracion inmediata tras el commit
- Rotacion de claves: manual via VPS SSH (sin automatizacion actual)

---

## Compliance

| Norma | Estado | Detalle |
|---|---|---|
| GDPR | IMPLEMENTADO | Consentimiento Art. 6.1.a, derecho al olvido, cifrado PII |
| OWASP Top 10 | IMPLEMENTADO | Ver tabla arriba |
| PCI DSS | PARCIAL | Sin pagos directos actualmente. Preparado para integracion |
| ISO 27001 | IMPLEMENTADO | RBAC en todos los endpoints protegidos |
| eIDAS | PLANIFICADO | Firma digital cualificada (fase futura) |
