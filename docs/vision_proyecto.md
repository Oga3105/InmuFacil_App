# Vision del Proyecto InmuFacil

**Version:** 12.0
**Fecha:** Marzo 2026
**Estado:** TFM en desarrollo activo — Frontend + Backend operacionales

---

## Resumen Ejecutivo

**InmuFacil** es una plataforma P2P (Peer-to-Peer) que transforma el proceso de compraventa inmobiliaria eliminando intermediarios tradicionales. Conecta directamente a compradores y vendedores particulares con herramientas de grado profesional: verificacion de identidad, negociacion guiada, contratos legales y cierre notarial automatizado.

**Filosofia Central:** *La tecnologia reemplaza la confianza — criptografia, IA y procesos automatizados sustituyen lo que antes hacian los intermediarios.*

---

## Concepto: P2P Puro

**Modelo Tradicional (Agencias):**
- Vendedor paga 3-5% de comision a una agencia
- Proceso opaco, dependiente de la reputacion del agente
- Costes de 6.000-15.000 EUR en transacciones tipicas

**Modelo InmuFacil (P2P):**
- La plataforma actua como garante tecnologico, no como intermediario comercial
- Verificacion KYC automatica (identidad, solvencia, documentacion)
- Comision de exito 0.5-1% solo en cierres completados
- Proceso de 17 hitos completamente trazable y auditado

---

## Estado Actual del Proyecto (Marzo 2026)

### Infraestructura Completa

| Componente | Estado | Detalle |
|---|---|---|
| Backend FastAPI | OPERACIONAL | 40+ routers, PostgreSQL 15, Docker |
| Frontend Flutter | OPERACIONAL | 50+ pantallas, Web + Android |
| Base de datos | OPERACIONAL | PostgreSQL en Docker, 30+ tablas |
| Autenticacion | OPERACIONAL | JWT + MFA Email + Google OAuth |
| KYC | OPERACIONAL | DNI/Pasaporte, Gemini Vision, cifrado AES-256 |
| Chat | OPERACIONAL | Mensajeria en tiempo real (WebSocket) |
| Contratos | OPERACIONAL | PDF dinamico con ReportLab, arras, firma digital |
| i18n | OPERACIONAL | 10 idiomas (es-ES, en-US, en-GB, en-CA, fr-FR, fr-CA, ca-ES, va-ES, eu-ES, gl-ES) |
| DNS/CDN | CONFIGURADO | Cloudflare — dominio inmufacil.com activo |
| VPS Despliegue | OPERACIONAL | Debian 12, IP 87.106.247.84, Docker + Nginx |

### Hitos Completados (Backend)

- **Hito 1-2:** Estructura base, autenticacion JWT, KYC cifrado AES-256-GCM
- **Hito 3:** Anti-agency filter (Escudo Anti-Inmo) — 30+ dominios, 40+ keywords
- **Hito 4:** Busqueda y filtrado de propiedades (SQL Query Builder dinamico)
- **Hito 5:** Visitas en Bloque (slot scheduling, dashboard de estado)
- **Hito 6:** Ofertas Transparentes (modelo transaccional, anti-auto-oferta)
- **Hito 7:** Negociacion Hibrida (contraofertas + Chat encriptado Fernet)
- **Hito 8:** Reserva y Senal (Payment Mock, idempotencia, bloqueo concurrencia)
- **Hito 9:** Verificacion Documental (Nota Simple OCR, ref. catastral, retencion datos)
- **Hito 10:** Tasacion (algoritmo comparativo, historico, mock fuentes externas)
- **Hito 11:** Financiacion (scoring hipotecario, simulacion cuotas, asesores)
- **Hito 12:** Contratos Dinamicos (ReportLab PDF, cuestionario legal, IA Gemini)
- **Hito 13:** Firma Digital (arquitectura hexagonal, mock provider, tokens OTP)
- **Hito 14:** Preparacion Notarial (dossier ZIP, SHA-256 manifest, unmasking)
- **Hito 15:** Cierre Definitivo (certificado digital, cambio estado SOLD/COMPLETED)
- **Hito 16:** Post-Sales Intelligence (ITP/notaria/registro, traspaso suministros)
- **Hito 17:** Mercado de Servicios (API unificada, RBAC, tickets, ordenes)

### Funcionalidades Frontend Implementadas (Flutter)

- Autenticacion completa: login, registro, recuperacion de contrasena, Google OAuth
- Perfil de usuario: foto, KYC, configuracion, notificaciones
- Publicacion de inmuebles: wizard 5 pasos con IA para descripcion
- Listado de propiedades: grid/mapa, comparador hibrido, SmartExplorerCard
- Mapa interactivo: flutter_map, OpenStreetMap, filtros geograficos
- Ofertas y negociacion: estado de oferta, contraofertas, timeline completo
- Arras: interview screen (3 paginas), buyer/seller stepper, revision de contrato
- Firma digital: flujo de firma simulado
- Notaria: pantalla de cita, FEIN, gestion tasacion
- Post-venta y entrega de llaves
- Solvency Passport: asistente de solvencia, segundo comprador
- KYC: verificacion de identidad con camara, validacion numero documento (NIE/NIF/Pasaporte)
- Chat: lista de conversaciones, detalle de chat
- Lifestyle: cuestionario de estilo de vida para matching de barrio
- Info y legal: pantalla de informacion (9 tipos), trust dashboard (Bronze/Silver/Gold)
- Admin: AI analytics, informe semanal
- GDPR: consentimiento IA (RGPD Art. 6.1.a), historial de consentimientos
- Onboarding Google: pantalla de consentimiento GDPR + seleccion tipo usuario
- 404 Lead Magnet: captura de emails en error de navegacion

---

## Seguridad por Capas (Defense in Depth)

### Capa 1a: Perimetro Estatico — Escudo Anti-Agencias v1
- Bloqueo de 30+ dominios de agencias inmobiliarias conocidas
- Deteccion de 40+ keywords profesionales en emails/nombres
- Validacion multi-factor para prevenir falsos positivos
- IP tracking y analisis de patrones de comportamiento

### Capa 1b: Perimetro Dinamico — Active Intelligence Shield 2.0
- Investigacion OSINT de telefono y nombre en portales inmobiliarios
- Analisis con IA (Gemini) de perfiles profesionales en LinkedIn/redes
- Risk scoring ponderado: telefono (+40), nombre (+40), email desechable (+20)
- Umbral de bloqueo configurable (>= 80 puntos)
- Fallback seguro: score=0 si APIs externas fallan
- Watermark ID unico por investigacion para trazabilidad

### Capa 1c: Moderacion Social — Community Shield
- Denuncias P2P entre usuarios verificados (3 categorias)
- +25 puntos de riesgo por denuncia de usuario distinto
- Re-investigacion OSINT automatica al 3er reporte
- Alertas SMTP al administrador (IONOS) para accion inmediata
- Prevencion de auto-denuncias y denuncias duplicadas

### Capa 2: Identidad — KYC + Google OAuth
- MFA por email (tokens 6 digitos, 15 min expiracion)
- Verificacion de identidad con Gemini Vision API
- Validacion de DNI/NIE/Pasaporte con checksum algoritmo oficial
- Redaccion automatica de datos sensibles del documento (MRZ, firma, equipo emisor)
- Google OAuth via google_sign_in + tokeninfo API (sin Firebase en cliente)
- Cifrado AES-256-GCM de datos personales (GDPR)

### Capa 3: Datos — Cifrado at-Rest
- AES-256-GCM con autenticacion de integridad (GCM tag)
- PBKDF2 con 100.000 iteraciones para derivacion de claves
- IV unico (12 bytes) por operacion de cifrado
- Master Key en variables de entorno, nunca en codigo

### Capa 4: Acceso — RBAC + Brute Force Prevention
- Roles: PARTICULAR, PROFESIONAL, FINANCIERO, ADMIN
- OAuth2 con JWT (HS256), expiracion configurable
- Bloqueo tras 3 intentos fallidos (15 minutos, ventana deslizante 30 min)
- Alerta MITRE T1110 en tiempo real

### Capa 5: Monitoreo — Audit Logging
- Logs estructurados JSON (python-json-logger)
- Filtros automaticos de datos sensibles en logs
- Eventos de seguridad con severidad y clasificacion MITRE
- Audit trail inmutable de operaciones sobre datos personales

### Capa 6: Desarrollo — DevSecOps
- Pre-commit hooks para deteccion de secretos hardcodeados
- TDD con pytest (backend) y flutter test (frontend)
- Protocolo de agentes internos (@Shield, @Jules, @Architect, etc.)
- Code review obligatorio via Pull Request antes de merge

---

## Compliance

| Normativa | Estado | Implementacion |
|---|---|---|
| GDPR | ACTIVO | Cifrado PII, derecho al olvido, consentimiento IA explicito (Art. 6.1.a) |
| OWASP Top 10 | ACTIVO | SQLi prevenido (Pydantic + ORM), XSS headers, CSRF proteccion |
| PCI DSS | PARCIAL | Cifrado at-rest, audit logging — integracion pagos reales pendiente |
| ISO 27001 | ACTIVO | RBAC, controles de acceso, gestion de secretos |
| MITRE ATT&CK | ACTIVO | Cobertura T1110, T1566, T1552, T1078 |
| eIDAS | PENDIENTE | Firma digital en mock; QTSP real (Signaturit/Logalty) en hoja de ruta |

---

## Stack Tecnologico Actualizado

### Backend
- **FastAPI 0.135.1** — framework async, OpenAPI 3.1 automatico
- **Python 3.13** — ultima version estable
- **PostgreSQL 15** — base de datos en produccion (Docker volume)
- **SQLAlchemy 2.0.48** — ORM async, migraciones via SQL raw (no Alembic)
- **Pydantic v2 2.12.5** — validacion y serializacion
- **python-jose** — JWT HS256
- **cryptography 46.0.5** — AES-256-GCM
- **EasyOCR** — analisis de documentos (DNI, Nota Simple)
- **google-genai >= 1.0** — Gemini Vision y descripcion de propiedades
- **ReportLab** — generacion de contratos PDF
- **httpx** — cliente HTTP async (verificacion Google tokeninfo)

### Frontend
- **Flutter SDK** — ultima version estable, targets: Web + Android (APK)
- **Riverpod 3.2.1** — gestion de estado reactiva (StateNotifier eliminado)
- **GoRouter 17.2.3** — navegacion declarativa con nested routes
- **Dio 5.9.2** — cliente HTTP con interceptores y FormData
- **flutter_map 8.2.2** — mapas con OpenStreetMap (sin coste de licencia)
- **easy_localization 3.0.3** — i18n con 10 idiomas
- **flutter_secure_storage** — almacenamiento seguro de JWT
- **google_sign_in 6.2.1** — Google OAuth sin Firebase en cliente
- **flutter_dotenv** — variables de entorno en build
- **image_picker + camera** — captura de imagenes KYC

### Infraestructura
- **Docker + Docker Compose** — contenedorizacion completa (backend + db)
- **Cloudflare** — DNS, proxy, SSL/TLS (dominio inmufacil.com)
- **VPS** — Debian 12, operacional (IP 87.106.247.84)
- **GitHub Actions** — CI/CD (workflows en .github/)

---

## Arquitectura de Datos — Propiedades

Las propiedades usan un esquema de "Tablas Satelite" para evitar columnas nulas masivas:
- `properties` — tabla principal con datos comunes
- `property_features` — caracteristicas opcionales (piscina, garaje, etc.)
- `property_documents` — documentos asociados (nota simple, CEE, fotos)
- `property_media` — imagenes en bytea (almacenamiento en BD)

El campo CEE (Certificado de Eficiencia Energetica) se gestiona como parte de property_documents y se muestra en el frontend mediante la widget CEE Display.

---

## Modelo de Negocio

- **Freemium**: Publicacion basica gratuita para vendedores particulares
- **Premium**: Funcionalidades avanzadas (destacados, analytics de mercado)
- **Servicios adicionales**: Tasaciones, asesoria legal, gestion hipotecaria
- **Comision por exito**: 0.5-1% solo en transacciones completadas (vs 3-5% de agencias)

---

## Roadmap

| Periodo | Objetivo |
|---|---|
| Q1 2026 (actual) | MVP completo — backend + frontend funcionales, Google OAuth, KYC IA |
| Q2 2026 | Despliegue produccion VPS, dominio inmufacil.com publico, APK Android |
| Q3 2026 | Integracion pasarela de pagos real, firma digital QTSP (Signaturit) |
| Q4 2026 | Expansion a principales ciudades espanolas, analytics avanzados |
| 2027 | Expansion internacional (Portugal, Francia) |

---

*Documento de Vision — InmuFacil Project*
*Version 12.0 — Marzo 2026*
*Actualizado con Google OAuth, Flutter App completa, CEE, Lifestyle, GDPR AI Consent*
