# Architecture Overview — InmuFacil

**Version:** 3.0
**Fecha:** Marzo 2026

---

## Vision General

InmuFacil sigue una arquitectura de tres capas desacopladas:

```
[Flutter Web / Android APK]
        |
        | HTTPS / REST + WebSocket
        |
[FastAPI Backend - Docker]
        |
        | SQLAlchemy ORM
        |
[PostgreSQL 15 - Docker Volume]
```

Toda la infraestructura se ejecuta en Docker Compose. En local, el frontend apunta a `http://localhost:8000/api/v1`. En produccion, el frontend es un build estatico servido por Nginx, y el backend esta detras de Cloudflare proxy.

---

## Frontend (Flutter)

### Stack
- **Flutter SDK** (ultima version estable)
- **Riverpod 3.2.1** — gestion de estado global y reactivo
- **GoRouter 17.1.0** — navegacion declarativa
- **Dio 5.9.2** — HTTP client con interceptores
- **flutter_map 8.2.2** — mapas OpenStreetMap
- **easy_localization 3.0.3** — i18n (9 idiomas)
- **google_sign_in 6.2.1** — OAuth social sin Firebase en cliente

### Estructura de Directorios

```
frontend/lib/
├── config/
│   ├── router/
│   │   └── app_router.dart          # Todas las rutas GoRouter
│   └── theme/                       # Material 3 theme
├── core/
│   ├── formatters/                  # CurrencyInputFormatter (enteros, separador miles)
│   └── widgets/                     # Widgets reutilizables globales
├── data/
│   ├── repositories/                # Implementacion de repos (Dio)
│   └── models/                      # DTOs y parsing JSON
├── domain/
│   └── entities/                    # Entidades de negocio puras (User, Property, etc.)
└── presentation/
    ├── providers/                   # Riverpod providers (auth, properties, offers, chat...)
    ├── screens/                     # 50+ pantallas organizadas por dominio
    │   ├── auth/                    # login, register, forgot_password
    │   ├── home/                    # home_screen
    │   ├── property/                # create/edit wizard, details, comparison
    │   ├── offers/                  # make offer, management, arras, timeline
    │   ├── kyc/                     # identity verification, status
    │   ├── solvency/                # passport, wizard, second buyer
    │   ├── chat/                    # list, detail
    │   ├── lifestyle/               # cuestionario de barrio
    │   ├── settings/                # notifications, AI consent history
    │   ├── onboarding/              # GDPR consent (Google), user type selection
    │   ├── info/                    # InfoScreen (9 tipos), TrustDashboard
    │   ├── admin/                   # AI analytics, weekly report
    │   └── not_found/               # 404 lead magnet
    └── widgets/                     # Widgets de presentacion reutilizables
        └── auth/
            └── google_sign_in_button.dart
```

### Patrones de Estado (Riverpod v3)

| Caso de uso | Patron |
|---|---|
| Autenticacion | `NotifierProvider<AuthNotifier, AuthState>` |
| Datos async + familia | `FutureProvider.autoDispose.family<T, Arg>` |
| Datos async simple | `AsyncNotifier<T>` + `AsyncNotifierProvider` |
| Mutaciones | Llamada Dio directa + `ref.invalidate(provider)` para refrescar |

**Regla de oro:** `StateNotifier` y `StateNotifierProvider` estan eliminados. Usar siempre patrones Riverpod v3.

### Navegacion (GoRouter v17)

Todas las rutas declaradas en `app_router.dart`. Rutas clave:
- `/` — Home (listado de propiedades)
- `/login`, `/register`, `/forgot-password`
- `/onboarding/consent`, `/onboarding/user-type` — flujo post-Google OAuth
- `/properties/:id` — detalle de propiedad
- `/properties/create` — wizard de publicacion (5 pasos)
- `/offers/:id/management` — gestion de oferta
- `/kyc` — verificacion de identidad
- `/solvency` — pasaporte de solvencia
- `/chat`, `/chat/:id`
- `/settings/ai-consent-history`
- `/profile`

### i18n

9 idiomas soportados via `easy_localization`:
- `es-ES` (principal), `en-US`, `fr-FR`, `de-DE`, `it-IT`, `pt-PT`, `zh-CN`, `ar-SA`, `ro-RO`

**Politica estricta:** Prohibido hardcodear strings en widgets. Obligatorio usar `.tr()`.

---

## Backend (FastAPI)

### Stack
- **FastAPI 0.135.1** + **Uvicorn** (async ASGI)
- **Python 3.13**
- **SQLAlchemy 2.0.48** — ORM con migraciones via SQL raw
- **Pydantic v2** — validacion de entrada/salida
- **PostgreSQL 15** — base de datos relacional
- **python-jose** — JWT HS256
- **cryptography** — AES-256-GCM para PII
- **google-genai** — Gemini Vision para KYC y descripcion AI
- **ReportLab** — generacion de contratos PDF
- **EasyOCR** — analisis de documentos DNI y Nota Simple
- **httpx** — verificacion de Google ID tokens via tokeninfo API

### Estructura de Directorios

```
backend/src/
├── config/
│   └── database.py              # Session factory, get_db dependency
├── models/
│   ├── __init__.py              # Exporta todos los modelos
│   ├── users.py                 # User, UserType, DNIStatus + google_id
│   ├── properties.py            # Property, PropertyFeature, PropertyMedia
│   ├── offers.py                # PropertyOffer, ContractData
│   ├── visits.py                # Visit, VisitSlot
│   ├── chat.py                  # ChatMessage
│   ├── contracts.py             # Contract, Signature
│   ├── notary.py                # Notary
│   ├── financing.py             # MortgageProfile, MortgageSimulation
│   └── ...                      # 15+ modelos adicionales
├── routes/
│   ├── auth.py                  # /auth/* — JWT, MFA, Google OAuth
│   ├── users.py                 # /users/* — perfil, foto
│   ├── properties.py            # /properties/* — CRUD, busqueda
│   ├── offers.py                # /offers/* — ciclo de vida completo
│   ├── visits.py                # /visits/* — block scheduling
│   ├── chat.py                  # /chat/* — mensajeria
│   ├── contracts.py             # /contracts/* — PDF, firma
│   ├── kyc.py                   # /kyc/* — verificacion identidad
│   ├── solvency.py              # /solvency/* — pasaporte solvencia
│   ├── solvency_passport.py     # /solvency-passport/*
│   ├── financing.py             # /financing/* — hipotecas
│   ├── notary.py                # /notaries/* — notarios, dossier
│   ├── signature.py             # /signature/* — firma digital
│   ├── timeline.py              # /timeline/* — estado transaccion
│   ├── tasacion.py              # /tasacion/* — valoracion
│   ├── post_sale.py             # /post-sale/* — post-venta
│   ├── handover.py              # /handover/* — entrega llaves
│   ├── services.py              # /services/* — mercado de servicios
│   ├── ai_description.py        # /ai/description
│   ├── ai_generate.py           # /ai/generate
│   ├── ai_consent.py            # /ai-consent/* — consentimiento GDPR
│   ├── comfort_index.py         # /comfort-index/*
│   ├── market_price.py          # /market-price/*
│   ├── neighborhood_twins.py    # /neighborhood-twins/*
│   ├── urban_growth.py          # /urban-growth/*
│   ├── nota_simple.py           # /nota-simple/*
│   ├── leads.py                 # /leads — lead magnet 404
│   ├── notifications.py         # /notifications/*
│   └── ...                      # ~40 routers en total
├── schemas/
│   └── base.py                  # Todos los schemas Pydantic v2
├── services/
│   ├── email_service.py         # MFA tokens, envio email
│   ├── kyc_service.py           # Redaccion DNI, validacion MIME
│   ├── contract_service.py      # Generacion PDF ReportLab
│   └── ...
└── utils/
    ├── security.py              # bcrypt, JWT, AES-256-GCM
    ├── filters.py               # Anti-agency filter
    └── ...
```

### Migraciones

El proyecto usa **SQL raw** en lugar de Alembic para mayor control y simplicidad:
- Archivos en `backend/migrations/*.sql`
- Se ejecutan manualmente via `docker exec -i <container> psql -U <user> -d <db> < migration.sql`
- Historial de migraciones en el nombre del archivo (timestamp o descripcion)

### Autenticacion — Flujo JWT

```
POST /auth/token   (email + password, form-urlencoded)
                   → JWT access_token (HS256)

POST /auth/register → crea usuario + envia email MFA
POST /auth/verify-email → confirma email con token 6 digitos

POST /auth/google  (google_id_token)
                   → verifica via tokeninfo API de Google (server-side)
                   → crea usuario o vincula google_id a cuenta existente
                   → devuelve JWT propio + is_new_user flag
```

El cliente Flutter almacena el JWT en `flutter_secure_storage` y lo incluye como `Authorization: Bearer <token>` en todas las peticiones autenticadas.

---

## Infraestructura y Despliegue

### Docker Compose

```yaml
services:
  backend:
    image: python:3.13
    command: uvicorn backend.src.main:app --host 0.0.0.0 --port 8000
    ports: ["8000:8000"]
    depends_on: [db]
    env_file: .env

  db:
    image: postgres:15
    volumes: [postgres_data:/var/lib/postgresql/data]
    environment:
      POSTGRES_USER: inmufacil_user
      POSTGRES_PASSWORD: ...
      POSTGRES_DB: inmufacil_db
```

### Cloudflare DNS

- **Dominio principal:** inmufacil.com
- **Registros A:** raiz (@) y www → IP del VPS
- **Registro A:** api → IP del VPS
- **Proxy:** Activado (icono naranja) en todos los registros publicos
- **SSL/TLS:** Full (strict) recomendado
- **Dominios adicionales:** inmufacil.es, inmufacil.store, inmufacil.info, inmueblefacilentreparticulares.com, inmueblefacilentreparticulares.es — todos redirigen a inmufacil.com

### VPS

- **Proveedor:** Nuevo VPS (configuracion en progreso, Marzo 2026)
- **SO:** Debian 12
- **Docker:** En instalacion
- **Nginx:** Requerido para servir build Flutter Web en /TFM y proxy al backend

### Ruta de Acceso en Produccion

```
https://inmufacil.com/TFM  →  Flutter Web build (index.html)
https://api.inmufacil.com  →  FastAPI backend (puerto 8000)
https://inmufacil.com      →  404 (no indexable publicamente)
```

---

## Seguridad Transversal

### Variables de Entorno (nunca en codigo)

| Variable | Descripcion |
|---|---|
| `DATABASE_URL` | URL completa de conexion PostgreSQL |
| `SECRET_KEY_JWT` | Clave secreta para firmar JWT |
| `INMUFACIL_MASTER_KEY` | Clave maestra AES-256 para cifrado PII |
| `GEMINI_API_KEY` | API key de Google Gemini |
| `GOOGLE_WEB_CLIENT_ID` | OAuth Web Client ID para Google Sign-In |

### CORS

El backend permite origenes especificos configurados por variable de entorno. En desarrollo: `http://localhost:8001`. En produccion: `https://inmufacil.com`.

### Headers de Seguridad

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Content-Security-Policy` configurada

---

## Decisiones de Arquitectura

Ver `docs/adrs/` para el historial completo de decisiones. ADRs clave:

| ADR | Decision |
|---|---|
| 001 | FastAPI + PostgreSQL + SQLAlchemy 2.0 |
| 010 | Flutter Mobile-First con Clean Architecture |
| 013 | Firma digital via arquitectura hexagonal (mock provider) |
| 014 | Preparacion notarial y dossier seguro |
| 016 | Google OAuth via tokeninfo API (sin Firebase) |
| 017 | Flutter app — Riverpod v3, GoRouter v17, Material 3 |
| 018 | Integracion Gemini AI para KYC y descripcion de propiedades |
| 019 | Consentimiento explicito IA (GDPR Art. 6.1.a) |
| 020 | Estrategia de despliegue Cloudflare + VPS |
