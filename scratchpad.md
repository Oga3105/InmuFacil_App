# Memoria del Proyecto InmuFacil

**Version:** 13.0
**Fecha ultima actualizacion:** 2026-04-22
**Estado:** MVP OPERACIONAL — Backend + Frontend desplegados en produccion
**Repositorio:** https://github.com/Oga3105/InmuFacil_App.git
**Rama principal de desarrollo:** `develop`
**URL produccion:** https://inmufacil.com/TFM/

---

## Infraestructura de Produccion

| Componente | Estado | Detalle |
|---|---|---|
| Backend FastAPI | OPERACIONAL | Docker container, puerto 8000 |
| PostgreSQL 15 | OPERACIONAL | Docker volume `inmufacil_postgres_data` |
| Nginx Proxy | OPERACIONAL | SSL via Cloudflare, puertos 80/443 |
| Frontend Flutter Web | OPERACIONAL | Servido en /TFM/ via Nginx |
| DNS/CDN | CONFIGURADO | Cloudflare — dominio inmufacil.com activo |
| VPS | OPERACIONAL | Debian 12, IP 87.106.247.84 |

### Credenciales de produccion (DB)
- Usuario: `user_admin`
- Base de datos: `inmufacil_prod`
- Directorio: `/opt/inmufacil`

---

## Hitos Completados (Backend — 17/17)

- **Hito 1-2:** Estructura base, autenticacion JWT, KYC cifrado AES-256-GCM
- **Hito 3:** Anti-agency filter (Escudo Anti-Inmo) — 30+ dominios, 40+ keywords
- **Hito 3b:** Propiedades e Inteligencia de Datos (CRUD + Satelites)
- **Hito 4:** Busqueda y filtrado + Visitas en Bloque (slot scheduling)
- **Hito 5:** Realizacion de Visitas (maquina de estados, dashboard)
- **Hito 6:** Ofertas Transparentes (anti-auto-oferta)
- **Hito 7:** Negociacion Hibrida (contraofertas + Chat encriptado Fernet)
- **Hito 8:** Reserva y Senal (Payment Mock, idempotencia)
- **Hito 9:** Verificacion Documental (Nota Simple OCR, ref. catastral)
- **Hito 10:** Tasacion (algoritmo comparativo, historico)
- **Hito 11:** Financiacion (scoring hipotecario, simulacion cuotas)
- **Hito 12:** Contratos Dinamicos (ReportLab PDF, cuestionario legal, IA Gemini)
- **Hito 13:** Firma Digital (arquitectura hexagonal, mock provider, tokens OTP)
- **Hito 14:** Preparacion Notarial (dossier ZIP, SHA-256 manifest)
- **Hito 15:** Cierre Definitivo (certificado digital, SOLD/COMPLETED)
- **Hito 16:** Post-Sales Intelligence (ITP/notaria/registro, traspaso suministros)
- **Hito 17:** Mercado de Servicios (API unificada, RBAC, tickets, ordenes)

---

## Funcionalidades Frontend Flutter (50+ pantallas)

### Core
- Login, registro, recuperacion de contrasena, Google OAuth
- Perfil de usuario: foto, edicion, cambio de contrasena
- KYC: captura de documento (camara/galeria), validacion numero (NIE/NIF/Pasaporte)
- Solvency Passport: asistente wizard, segundo comprador
- Chat P2P: lista de conversaciones, detalle con mensajeria, acciones rapidas
- Notificaciones push (backend)

### Propiedades
- Wizard de publicacion 5 pasos (tipo/ubicacion, detalles/precio, fotos, descripcion IA, preview)
- Listado: grid inteligente (SmartExplorerCard), filtros avanzados
- Mapa interactivo: flutter_map + OpenStreetMap, filtros geograficos
- Comparador hibrido de propiedades
- CEE (Certificado Eficiencia Energetica): display en tarjeta
- ComfortRadar: indice de confort por barrio
- Lifestyle questionnaire: matching de barrio

### Visitas
- Calendario de disponibilidad del vendedor
- Reserva de slots por el comprador (con notas/comentarios)
- Seccion proximas/pasadas con orden inteligente
- Botones Aceptar/Rechazar con texto para el vendedor
- Reprogramacion y cancelacion
- Prevencion de duplicados (un comprador, una visita activa por inmueble)
- Slots cancelados se liberan para rebooking

### Flujo de Compraventa
- Make Offer con validacion monetaria (solo enteros, separador de miles)
- Offer Management: contraofertas, timeline de estados
- Arras Interview (3 paginas), buyer/seller stepper
- Smart Bid Risk, pre-offer tax summary
- Transaction Timeline: tasacion, FEIN, notaria, firma, post-venta, entrega llaves

### Legal y Seguridad
- Info screen (9 tipos de informacion legal/funcional)
- Trust Dashboard (Bronze/Silver/Gold)
- GDPR AI Consent (RGPD Art. 6.1.a), historial de consentimientos

### i18n
- 9 idiomas: es-ES, en-US, fr-FR, de-DE, it-IT, pt-PT, zh-CN, ar-SA, ro-RO

---

## PRs Recientes (Abril 2026)

| PR | Descripcion | Estado |
|---|---|---|
| #246 | fix(chat): remove non-functional documents button | Merged |
| #245 | feat(visits): split into upcoming and past sections | Merged |
| #244 | feat(visits): buyer notes and labeled action buttons | Merged |
| #243 | fix(visits): free slots when visit is cancelled | Merged |
| #242 | feat(visits): complete visit flow (approve/reject, duplicate guard, status banner) | Merged |
| #241 | fix(visit): cancel endpoint and timezone offset | Merged |
| #240 | fix(visits): appbar styling and booking 422 fix | Merged |
| #239 | fix(comfort): remove cached label and improve AI disclaimer | Merged |

---

## Seguridad

### Variables de Entorno (NUNCA en git)
- `DATABASE_URL` — URL de conexion PostgreSQL
- `SECRET_KEY_JWT` — firma JWT
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
| `README.md` | ACTUALIZADO (Abril 2026) | Indice principal del proyecto |
| `docs/vision_proyecto.md` | ACTUALIZADO (v12.0) | Vision completa del proyecto |
| `docs/ARCHITECTURE.md` | ACTUALIZADO (v3.0) | Stack completo backend + frontend |
| `docs/API_REFERENCE.md` | ACTUALIZADO (v3.0) | Todos los endpoints actuales |
| `docs/DEPLOYMENT_GUIDE.md` | ACTUALIZADO (v2.0) | VPS + Docker + Cloudflare |
| `docs/GETTING_STARTED.md` | ACTUALIZADO (v2.0) | Setup completo local + produccion |
| `docs/adrs/001-020` | Existentes | Decisiones arquitectonicas |
