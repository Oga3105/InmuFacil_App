# 🏠🔐 InmuFacil

**Plataforma P2P de Compraventa Inmobiliaria con Seguridad DevSecOps**

InmuFacil es una plataforma peer-to-peer que elimina intermediarios en las transacciones inmobiliarias, sustituyendo la confianza tradicional de las agencias por tecnologia de cifrado de grado militar y validacion de identidad automatizada.

🎓 **TFM (Trabajo Fin de Master) — Ciberseguridad / Desarrollo**

---

## 📚 Documentacion del Proyecto (Single Source of Truth)

La documentacion estructurada reside exclusivamente en la carpeta `/docs`.

| Documento | Enlace |
|-----------|--------|
| 🚀 Guia Rapida | [GETTING_STARTED.md](docs/GETTING_STARTED.md) |
| 🏗️ Arquitectura | [ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| ☁️ Despliegue (VPS + Docker + Cloudflare) | [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) |
| 📡 Referencia de API | [API_REFERENCE.md](docs/API_REFERENCE.md) |
| 📦 Modelos de Datos | [CONTRACTS.md](docs/CONTRACTS.md) |
| 🛡️ Seguridad y OWASP | [SECURITY.md](docs/SECURITY.md) |
| 🔑 Gestion de Secretos | [SECRETS.md](docs/SECRETS.md) |
| 🔄 Maquinas de Estado | [STATE_MACHINE.md](docs/STATE_MACHINE.md) |
| 🧪 Testing | [TESTING_STRATEGY.md](docs/TESTING_STRATEGY.md) |
| 🎨 UI y Estilos | [THEME_CUSTOMIZATION.md](docs/THEME_CUSTOMIZATION.md) |
| 🔧 Troubleshooting | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| 📋 Decision Records | [adrs/](docs/adrs/) |

---

## 🎯 Vision del Proyecto

**"Donde la tecnologia reemplaza la confianza"**

InmuFacil permite que particulares compren y vendan propiedades directamente, sin agencias inmobiliarias, utilizando:
- 🤖 **Gemini AI** para asistencia inteligente y validacion
- 🔐 **Cifrado AES-256-GCM** para proteccion de datos sensibles (Vault Activado)
- 🪪 **Verificacion KYC automatizada** con redaccion de PII (100% opacidad verificada)
- 🛡️ **Escudo Anti-Agencias** para mantener el ecosistema P2P puro
- 🧠 **Active Intelligence Shield 2.0** con OSINT e IA para deteccion avanzada
- 👥 **Community Shield** con denuncias P2P y alertas automaticas al admin

---

## 📊 Estado Actual del Proyecto

**Estado:** ✅ MVP completo — Backend + Frontend operacionales en produccion
**URL:** 🌐 https://inmufacil.com/TFM/
**Rama Activa:** `develop`

### ✅ Hitos Backend (17/17 completados)

| # | Hito | Descripcion |
|---|------|-------------|
| 1-2 | 🏗️ Estructura + KYC | Base, autenticacion JWT, cifrado AES-256-GCM, Vault |
| 3 | 🔑 Autenticacion | JWT + MFA Email + Google OAuth + Escudo Anti-Agencias |
| 3b | 🏘️ Propiedades | CRUD Vendedor + Arquitectura Datos Satelite |
| 4 | 📅 Visitas | Smart Scheduling, Slots Dinamicos, Dashboard |
| 5 | 👁️ Ejecucion Visitas | Maquina de Estados, Approve/Reject, RBAC |
| 6 | 💰 Ofertas | Modelo Transparente, Anti-Auto-Oferta |
| 7 | 🤝 Negociacion | Contraofertas, Chat Encriptado Fernet |
| 8 | 💳 Reserva y Senal | Payment Mock, Idempotencia, Concurrencia |
| 9 | 📄 Verificacion Documental | Nota Simple OCR, Ref. Catastral, AES-256 |
| 10 | 📈 Tasacion | Algoritmo Comparativo, Historico |
| 11 | 🏦 Financiacion | Scoring Hipotecario, Simulacion Cuotas |
| 12 | 📝 Contratos | ReportLab PDF, Cuestionario Legal, Gemini AI |
| 13 | ✍️ Firma Digital | Arquitectura Hexagonal, Tokens OTP |
| 14 | ⚖️ Prep. Notarial | Dossier ZIP, SHA-256 Manifest |
| 15 | 🏁 Cierre Definitivo | Certificado Digital, Estado SOLD |
| 16 | 📊 Post-Sales | ITP, Suministros, Compliance |
| 17 | 🛒 Mercado Servicios | API Unificada, RBAC, Tickets |

### 📱 Frontend Flutter (50+ pantallas)

- 🔑 Autenticacion completa: login, registro, Google OAuth, MFA
- 👤 Perfil de usuario: foto, KYC, configuracion, notificaciones
- 🏘️ Publicacion de inmuebles: wizard 5 pasos con IA para descripcion
- 🗺️ Mapa interactivo: flutter_map, OpenStreetMap, filtros geograficos
- 📋 Listado: grid inteligente (SmartExplorerCard), comparador hibrido
- 💬 Chat P2P: mensajeria, acciones rapidas (visita, oferta)
- 📅 Visitas: calendario, reserva de slots, proximas/pasadas
- 💰 Ofertas y negociacion: contraofertas, timeline completo
- 📝 Arras: interview screen, buyer/seller stepper
- ✍️ Firma digital, notaria, post-venta y entrega de llaves
- 🪪 Solvency Passport: asistente de solvencia
- 🌍 i18n: 10 idiomas (es-ES, en-US, en-GB, en-CA, fr-FR, fr-CA, ca-ES, va-ES, eu-ES, gl-ES)
- 📧 Contacto: formulario autenticado con rate limiting (3 msg/24h)
- 🔒 GDPR: consentimiento IA (RGPD Art. 6.1.a), trust dashboard

### ⚙️ DevOps

- 🔍 CodeQL para analisis de seguridad Python
- 🤖 Dependabot (Python, Flutter, GitHub Actions)
- 🚫 Pre-commit hooks (deteccion de secretos)
- 📝 Templates de issues y PR con checklists
- 🚀 Deploy scripts (backend + frontend) automatizados

---

## 🏗️ Stack Tecnologico

### Backend
| Tecnologia | Version | Uso |
|------------|---------|-----|
| FastAPI | 0.136.3 | Framework async, OpenAPI 3.1 |
| Python | 3.11 | Runtime (Docker prod) |
| PostgreSQL | 15 | Base de datos (Docker) |
| SQLAlchemy | 2.0.50 | ORM |
| Pydantic | v2 | Validacion y serializacion |
| cryptography | 48.0.0 | AES-256-GCM |
| google-genai | >= 2.0.1 | Gemini Vision + IA |
| ReportLab | - | Generacion PDF contratos |

### Frontend
| Tecnologia | Version | Uso |
|------------|---------|-----|
| Flutter | Latest stable | Web + Android |
| Riverpod | 3.2.1 | Estado reactivo |
| GoRouter | 17.2.3 | Navegacion declarativa |
| Dio | 5.9.2 | HTTP + interceptores JWT |
| flutter_map | 8.2.2 | Mapas OpenStreetMap |
| easy_localization | 3.0.3 | i18n (10 idiomas) |
| flutter_secure_storage | 10.1.0 | Almacenamiento seguro JWT |
| google_sign_in | 6.3.0 | Google OAuth |

### Infraestructura
| Componente | Detalle |
|------------|---------|
| 🐳 Docker + Compose | Contenedorizacion (backend + db + nginx) |
| ☁️ Cloudflare | DNS, proxy, SSL/TLS (inmufacil.com) |
| 🖥️ VPS Debian 12 | Produccion operacional |
| 🔀 Nginx | Reverse proxy + static files |

---

## 🛡️ Stack de Seguridad

### 🔐 Vault de Cifrado (Activado)
- **AES-256-GCM**: Cifrado autenticado para DNI y telefonos
- **Master Key Management**: Clave maestra de 32 bytes (base64)
- **Fail-Safe Startup**: Aplicacion no arranca sin clave valida
- **PBKDF2**: Derivacion de claves con 100,000 iteraciones
- **Bcrypt**: Hashing de contrasenas con salt automatico

### 🪪 Redaccion Automatica de PII (Verificada 100%)
- **DNI Image Redaction**: MRZ, firma, equipo emisor — 170,000+ pixeles verificados
- **Cifrado en Reposo**: DNI y telefonos cifrados en base de datos
- **Zero-Log Policy**: Datos sensibles nunca en logs

### 🏰 Arquitectura DevSecOps
- Security by Design / Security by Default / Defense in Depth (6 capas)
- Secure CORS: Origenes especificos (NO wildcards)
- Security Headers: X-Content-Type-Options, X-Frame-Options, CSP

### ⚔️ Prevencion de Amenazas (MITRE ATT&CK)
| Tecnica | Mitigacion |
|---------|-----------|
| T1110 (Brute Force) | Rate limiting + bloqueo temporal |
| T1566 (Phishing) | Validacion MIME de archivos |
| T1552 (Unsecured Credentials) | Cifrado at-rest + vault |
| T1078 (Valid Accounts) | MFA por email |

---

## 🚀 Instalacion y Configuracion

### Requisitos Previos
- 🐍 Python 3.11+
- 💙 Flutter SDK
- 🐳 Docker + Docker Compose
- 📦 Git

### Instalacion

```bash
# Clonar repositorio
git clone https://github.com/Oga3105/InmuFacil_App.git
cd InmuFacil_App
git checkout develop

# Backend
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# .venv\Scripts\activate   # Windows
pip install -r requirements.txt

# Frontend
cd frontend
flutter pub get
```

### 🔑 Configuracion de Seguridad

> ⚠️ **IMPORTANTE:** La aplicacion NO ARRANCARA sin la configuracion correcta del vault de cifrado.

```bash
cp .env.example .env
# Editar .env con las claves requeridas (ver .env.example)
```

Variables criticas:
| Variable | Descripcion |
|----------|-------------|
| `INMUFACIL_MASTER_KEY` | Cifrado AES-256 PII (32 bytes, base64) |
| `SECRET_KEY_JWT` | Firma JWT |
| `DATABASE_URL` | Conexion PostgreSQL |
| `GEMINI_API_KEY` | API de Gemini |
| `GOOGLE_WEB_CLIENT_ID` | OAuth Web Client ID |

Ademas del `.env`, el build Docker requiere `firebase-key.json` en la raiz
del proyecto (no esta en git). Ver `backend/README.md` para detalles.

### ▶️ Ejecutar

```bash
# Backend (desarrollo)
uvicorn backend.main:app --reload
# 📡 http://localhost:8000 — API
# 📖 http://localhost:8000/docs — Swagger

# Frontend (desarrollo)
cd frontend
flutter run -d chrome --web-port 8001

# Docker (produccion)
docker compose up -d
```

---

## 🧪 Testing

```bash
# Backend
pytest tests/ -v
pytest tests/ --cov=backend --cov-report=html

# Frontend
cd frontend
flutter test
flutter test --coverage
```

---

## ⚖️ Compliance

| Normativa | Estado | Implementacion |
|-----------|--------|---------------|
| 🇪🇺 GDPR | ✅ Activo | Cifrado PII, derecho al olvido, consentimiento IA (Art. 6.1.a) |
| 🔒 OWASP Top 10 | ✅ Activo | SQLi prevenido (Pydantic + ORM), XSS headers, CSRF |
| 💳 PCI DSS | ⏳ Parcial | Cifrado at-rest, audit logging — pagos reales pendientes |
| 📋 ISO 27001 | ✅ Activo | RBAC, controles de acceso, gestion de secretos |
| ⚔️ MITRE ATT&CK | ✅ Activo | Cobertura T1110, T1566, T1552, T1078 |
| ✍️ eIDAS | ⏳ Pendiente | Firma digital en mock; QTSP real en hoja de ruta |

---

## 📁 Estructura del Proyecto

```
InmuFacil_Project/
├── 🔧 backend/
│   ├── main.py                    # FastAPI application
│   └── src/
│       ├── config/                # Database, settings
│       ├── models/                # SQLAlchemy models (30+ tablas)
│       ├── routes/                # API routers (40+)
│       ├── schemas/               # Pydantic schemas
│       ├── services/              # Email, KYC, AI, contracts
│       └── utils/                 # Security, crypto, filters
├── 📱 frontend/
│   └── lib/
│       ├── core/                  # Config, formatters, utils
│       ├── data/                  # Repositories, data sources
│       ├── domain/                # Entities, use cases
│       └── presentation/
│           ├── screens/           # 50+ UI screens
│           ├── widgets/           # Reusable components
│           └── providers/         # Riverpod state management
├── 📚 docs/                       # Documentacion tecnica
│   └── adrs/                      # Decision records (23+)
├── 🤖 .agents/                    # Agent governance & protocols
│   ├── roles/                     # @Architect, @Jules, @Shield...
│   └── protocols/                 # TDD, pre-commit, git governance
├── 🔀 nginx/                      # Proxy configuration
├── 🧪 tests/                      # Backend test suite
├── 🐳 docker-compose.yml          # Local development
├── 🐳 docker-compose.prod.yml     # Production
├── 🚀 deploy-backend.sh           # Backend deploy script
├── 🚀 deploy-frontend.sh          # Frontend deploy script
└── 📦 requirements.txt            # Python dependencies
```

---

## 🤝 Contribucion

Este proyecto sigue estandares DevSecOps estrictos:

1. ✅ Todas las contribuciones en rama `develop`
2. 🧪 Tests obligatorios para nuevas features (TDD)
3. 🚫 Pre-commit hooks activos (deteccion de secretos)
4. 📋 Pull Request obligatoria con code review
5. 📚 Documentacion actualizada antes de merge

---

**🏠🔐 InmuFacil — Donde la tecnologia reemplaza la confianza**
