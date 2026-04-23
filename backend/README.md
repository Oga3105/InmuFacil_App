# 🔧 InmuFacil — Backend

Servidor API construido con **FastAPI** y **PostgreSQL** para el ecosistema InmuFacil.

## 📚 Documentacion

Para mantener una fuente unica de la verdad, toda la documentacion reside en el directorio raiz `/docs`.

| Documento | Enlace |
|-----------|--------|
| 🏗️ Arquitectura (Satelites DB, FastAPI) | [ARCHITECTURE.md](../docs/ARCHITECTURE.md) |
| 📡 Referencia de API | [API_REFERENCE.md](../docs/API_REFERENCE.md) |
| 📦 Contratos de Datos | [CONTRACTS.md](../docs/CONTRACTS.md) |
| 🔄 Maquinas de Estado (Core Logic) | [STATE_MACHINE.md](../docs/STATE_MACHINE.md) |
| ☁️ Despliegue con Docker | [DEPLOYMENT_GUIDE.md](../docs/DEPLOYMENT_GUIDE.md) |
| 🛡️ Seguridad y OWASP | [SECURITY.md](../docs/SECURITY.md) |

## 🏗️ Estructura

```
backend/
├── main.py                  # FastAPI application entry point
└── src/
    ├── config/
    │   ├── database.py      # SQLAlchemy engine + session
    │   └── settings.py      # Environment config
    ├── models/              # SQLAlchemy models (30+ tablas)
    │   ├── base.py          # Declarative base
    │   ├── user.py          # Users, KYC, roles
    │   ├── property.py      # Properties + satelites
    │   ├── visits.py        # VisitWindow, VisitAppointment
    │   ├── offers.py        # PropertyOffer, OfferMessage
    │   └── ...
    ├── routes/              # API routers (40+)
    │   ├── auth.py          # JWT, MFA, Google OAuth
    │   ├── properties.py    # CRUD + busqueda
    │   ├── visits.py        # Scheduling + estado
    │   ├── offers.py        # Negociacion
    │   └── ...
    ├── schemas/             # Pydantic v2 schemas
    ├── services/            # Email, KYC, AI, contracts
    └── utils/               # Security, crypto, filters
```

## 🚀 Inicio Rapido

```bash
# 1. Crear y activar entorno virtual
python -m venv .venv
source .venv/bin/activate    # Linux/Mac
# .venv\Scripts\activate     # Windows

# 2. Instalar dependencias
pip install -r ../requirements.txt

# 3. Configurar variables de entorno
cp ../.env.example ../.env
# Editar .env con las claves requeridas

# 4. Levantar servicio
uvicorn backend.main:app --reload

# 📡 API: http://localhost:8000
# 📖 Swagger: http://localhost:8000/docs
```

## 🧪 Testing

```bash
pytest tests/ -v
pytest tests/ --cov=backend --cov-report=html
```

## 🛡️ Seguridad

- 🔐 AES-256-GCM para cifrado de PII (DNI, telefono)
- 🔑 JWT con MFA por email
- 🛡️ Escudo Anti-Agencias v1 (30+ dominios, 40+ keywords)
- 🧠 Active Intelligence Shield 2.0 (OSINT + IA + scoring ponderado)
- 👥 Community Shield (denuncias P2P + re-investigacion automatica)
- 📧 Alertas de moderacion al admin via SMTP (IONOS)
- ⚔️ Prevencion MITRE ATT&CK (T1110, T1566, T1552, T1078)
- ✅ RBAC en todos los endpoints sensibles
- 🚫 Pre-commit hooks para deteccion de secretos
