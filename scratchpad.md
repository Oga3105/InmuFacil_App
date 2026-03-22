# Memoria del Proyecto InmuFacil

**Version:** 12.0
**Fecha ultima actualizacion:** 2026-03-22
**Estado:** DOCUMENTACION ACTUALIZADA — Google OAuth implementado
**Repositorio:** https://github.com/Oga3105/InmuFacil_App.git
**Rama principal de desarrollo:** `develop`
**Ultimo commit en develop:** ac02e0b — Merge PR #160 (lifestyle integration)
**En progreso:** `feature/google-oauth-registration` (PR #161 abierto)

---

## Estado de Ramas

| Rama | Estado | Descripcion |
|---|---|---|
| `develop` | Rama principal | Base de todo el desarrollo |
| `feature/google-oauth-registration` | PR #161 abierto | Google OAuth implementado, pendiente merge |
| `docs/update-project-documentation-march-2026` | En progreso | Esta rama — actualizacion docs |

---

## Estrategia de Ramificacion (Git Flow)

- **Rama de Desarrollo:** `develop`
- **Rama Produccion Estable:** `main`
- **Politica:** Todo desarrollo en ramas `feature/` o `fix/`. PR obligatoria para merge a `develop`. Solo versiones validadas fusionan a `main`.

---

## Hitos Completados (Backend FastAPI)

### Hito 1-2: Estructura Base + KYC Seguro
- Autenticacion JWT completa (registro, login, MFA email, recuperacion contrasena)
- KYC: cifrado AES-256-GCM para DNI/telefono, redaccion automatica, validacion MIME
- MFA: tokens 6 digitos, 15 min expiracion
- Brute Force Prevention (MITRE T1110)
- Audit logging sin datos sensibles

### Hito 3: Escudo Anti-Agencias
- Filtro heurístico: 30+ dominios, 40+ keywords
- Validacion multi-factor, IP tracking, 15+ tests

### Hito 4: Busqueda y Filtrado
- SQL Query Builder dinamico (precio, m2, habitaciones, tipo, georeferencia)
- Prevencion SQL Injection via Pydantic + ORM

### Hito 5: Visitas en Bloque
- Algoritmo de slot scheduling automatico
- Dashboard de estado (Requested, Approved, Completed)
- RBAC: Owner vs Buyer

### Hito 6: Ofertas Transparentes
- Modelo `PropertyOffer` transaccional
- Prevencion auto-ofertas, estados gestionados

### Hito 7: Negociacion Hibrida
- Protocolo de contraofertas
- Chat encriptado (Fernet) activado bajo demanda
- Historial de negociacion inmutable

### Hito 8: Reserva y Senal
- Payment Mock Provider
- Idempotencia, bloqueo de concurrencia
- Visibilidad configurable al reservar

### Hito 9: Verificacion Documental
- OCR de Nota Simple (EasyOCR)
- Deteccion automatica de Referencia Catastral
- Politica de retencion y borrado seguro

### Hito 10: Tasacion
- Algoritmo de valoracion comparativa
- Historico de tasaciones
- Mock de fuentes externas

### Hito 11: Financiacion
- Scoring hipotecario, simulacion de cuotas
- Mock meta-buscador: iAhorro, BBVA, Santander
- Rol FINANCIERO y asignacion de asesores

### Hito 12: Contratos Dinamicos
- Generacion PDF con ReportLab (Arras Penitenciales)
- Cuestionario legal (clausulas condicionales: Cuerpo Cierto, AML, etc.)
- Analisis de contratos propios con Gemini AI
- Consentimiento expreso + liability waiver en DB

### Hito 13: Firma Digital
- Arquitectura hexagonal (Ports & Adapters)
- Mock provider con tokens OTP (secrets.token_urlsafe)
- Trazabilidad de estados: SIGNING_PENDING -> SIGNED

### Hito 14: Preparacion Notarial
- Gestion de notarios colaboradores
- Dossier ZIP: contrato, nota simple, DNIs desencriptados, MANIFEST.txt SHA-256
- The Great Unmasking (des-anonimizacion controlada)

### Hito 15: Cierre Definitivo
- Automatizacion de estado SOLD/COMPLETED
- Certificado de Cierre Digital
- Integracion con Timeline

### Hito 16: Post-Sales Intelligence
- Estimador de costes (ITP, notaria, registro)
- Traspaso seguro de suministros (CUPS, facturas cifradas)
- Compliance legal (disclaimers obligatorios)

### Hito 17: Mercado de Servicios
- API Router unificado `/services/*`
- RBAC (Admin/Provider/User)
- Tickets y seguimiento de ordenes
- Modelos extensibles (notarios, tasadores, mudanzas)

---

## Funcionalidades Frontend Flutter (Completadas)

### Core
- Login, registro, recuperacion de contrasena
- Google OAuth (PR #161 — pendiente merge)
- Perfil de usuario: foto, edicion, cambio de contrasena
- KYC: captura de documento (camara/galeria), validacion numero (NIE/NIF/Pasaporte con checksum)
- Solvency Passport: asistente wizard, segundo comprador
- Chat: lista de conversaciones, detalle con mensajeria
- Notificaciones push (backend)

### Propiedades
- Wizard de publicacion 5 pasos (tipo/ubicacion → detalles/precio → fotos → descripcion IA → preview)
- Listado: grid inteligente (SmartExplorerCard), filtros avanzados
- Mapa interactivo: flutter_map + OpenStreetMap, filtros geograficos
- Comparador hibrido de propiedades
- CEE (Certificado Eficiencia Energetica): display en tarjeta de propiedad
- ComfortRadar: widget de indice de confort por barrio
- Lifestyle questionnaire: matching de barrio por estilo de vida

### Flujo de Compraventa
- Make Offer screen con validacion monetaria
- Offer Management: contraofertas, timeline de estados
- Arras Interview (3 paginas)
- Arras buyer/seller stepper
- Smart Bid Risk: analisis de riesgo de oferta
- Pre-offer tax summary (ITP estimado)
- Transaction Timeline completo: tasacion, FEIN, notaria, firma, post-venta, entrega llaves

### Legal y Seguridad
- Info screen (9 tipos de informacion legal/funcional)
- Trust Dashboard (Bronze/Silver/Gold segun nivel de verificacion)
- GDPR AI Consent: consentimiento explicito por tipo de IA (RGPD Art. 6.1.a)
- AI Consent History screen (historial de cambios)
- Onboarding Google: GDPR consent + user type selection

### Admin
- AI analytics dashboard
- Weekly report screen

### i18n
- 9 idiomas: es-ES, en-US, fr-FR, de-DE, it-IT, pt-PT, zh-CN, ar-SA, ro-RO

---

## Infraestructura

### DNS / Cloudflare
- Nameservers de IONOS cambiados a Cloudflare
- Zone ID: 117f5abc1238908b73a3cea2c8b2bd6a
- Registros A configurados: raiz, www, api → IP VPS
- Proxy Cloudflare activo (icono naranja)
- Dominio principal: inmufacil.com

### VPS
- Nuevo VPS adquirido (Marzo 2026), configuracion en progreso
- SO: Debian 12
- Docker: instalacion pendiente

### Local
- Docker Compose con backend (FastAPI puerto 8000) + PostgreSQL 15
- Frontend corre en localhost:8001 (flutter run -d chrome --web-port 8001)

---

## Pendientes

### Inmediatos
- [ ] Completar instalacion Docker en nuevo VPS
- [ ] Configurar Nginx en VPS para servir Flutter Web en /TFM
- [ ] Build Flutter Web produccion y subir al VPS
- [ ] Merge PR #161 (Google OAuth) tras completar instalacion Docker y verificar en produccion
- [ ] Cambiar contrasena root del VPS (seguridad)
- [ ] Configurar GOOGLE_WEB_CLIENT_ID en ambos .env con credencial real de Google Cloud

### A medio plazo
- [ ] Configurar dominios adicionales (inmufacil.es, etc.) con redirect rules en Cloudflare
- [ ] Activar HTTPS Full (strict) en Cloudflare una vez VPS tenga certificado
- [ ] Configurar `X-Robots-Tag: noindex` durante fase TFM
- [ ] Configurar GitHub Actions para CI/CD automatico

---

## Seguridad

### Variables de Entorno (NUNCA en git)
- `DATABASE_URL` — URL de conexion PostgreSQL
- `SECRET_KEY_JWT` — firma JWT (cambiar en produccion)
- `INMUFACIL_MASTER_KEY` — cifrado AES-256 PII
- `GEMINI_API_KEY` — API de Gemini
- `GOOGLE_WEB_CLIENT_ID` — OAuth Web Client ID

### Compliance activo
- GDPR: cifrado PII, consentimiento IA explicito, derecho al olvido
- OWASP Top 10: SQLi, XSS, CSRF mitigados
- MITRE ATT&CK: T1110, T1566, T1552, T1078
- ISO 27001: RBAC implementado

---

## Documentacion

| Archivo | Estado | Contenido |
|---|---|---|
| `docs/vision_proyecto.md` | ACTUALIZADO (v12.0) | Vision completa con estado actual Marzo 2026 |
| `docs/ARCHITECTURE.md` | ACTUALIZADO (v3.0) | Stack completo backend + frontend |
| `docs/API_REFERENCE.md` | ACTUALIZADO (v3.0) | Todos los endpoints actuales |
| `docs/DEPLOYMENT_GUIDE.md` | ACTUALIZADO (v2.0) | VPS + Docker + Cloudflare |
| `docs/GETTING_STARTED.md` | ACTUALIZADO (v2.0) | Setup completo local + produccion |
| `docs/adrs/001-015` | Existentes | Decisiones arquitectonicas previas |
| `docs/adrs/016` | NUEVO | Google OAuth sin Firebase |
| `docs/adrs/017` | NUEVO | Flutter Clean Architecture + Riverpod v3 |
| `docs/adrs/018` | NUEVO | Integracion Gemini AI |
| `docs/adrs/019` | NUEVO | GDPR AI Consent (RGPD Art. 6.1.a) |
| `docs/adrs/020` | NUEVO | Cloudflare + VPS deployment |
