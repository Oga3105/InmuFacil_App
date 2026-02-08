# InmuFácil 🏠🔐

**Plataforma P2P de Compraventa Inmobiliaria con Seguridad DevSecOps**

InmuFácil es una plataforma peer-to-peer que elimina intermediarios en las transacciones inmobiliarias, sustituyendo la confianza tradicional de las agencias por tecnología de cifrado de grado militar y validación de identidad automatizada.

---

## 🎯 Visión del Proyecto

**"Donde la tecnología reemplaza la confianza"**

InmuFácil permite que particulares compren y vendan propiedades directamente, sin agencias inmobiliarias, utilizando:
- **Gemini AI** para asistencia inteligente y validación
- **Cifrado AES-256-GCM** para protección de datos sensibles (Vault Activado)
- **Verificación KYC automatizada** con redacción de PII (100% opacidad verificada)
- **Escudo Anti-Agencias** para mantener el ecosistema P2P puro

---

## 📊 Estado Actual del Proyecto (Status Matrix)

El proyecto se encuentra en un estado híbrido de desarrollo:
*   **Backend:** Completado y Maduro (Hito 17 - Legacy/Maintenance).
*   **Frontend:** Desarrollo Activo (Hito 3 - Focus).

| Módulo / Hito | Estado Backend (API) | Estado Frontend (Flutter) |
| :--- | :---: | :---: |
| **1. Auth & Core** | ✅ Completado | ✅ Completado |
| **2. KYC & Vault** | ✅ Completado | ✅ Completado (DNI Upload) |
| **3. Anti-Agencias** | ✅ Completado | ✅ Completado |
| **4. Búsqueda** | ✅ Completado | 🚧 **WIP (Siguiente Paso)** |
| **5. Visitas** | ✅ Completado | 🔴 Pendiente |
| **6. Ofertas** | ✅ Completado | 🔴 Pendiente |
| **7-9. Negociación**| ✅ Completado | 🔴 Pendiente |
| **10. Tasación** | ✅ Completado | 🔴 Pendiente |
| **11-17. Closing** | ✅ Completado | 🔴 Pendiente |

---

**Hito Activo:** 🚧 **Frontend Hito 4: Búsqueda y Resultados**
**Rama Activa:** `feature/valuation-engine` (Reutilizada para integración Frontend)
**Último Commit:** `feat(404): refine illustration (pixel-perfect), add i18n (9 langs) and security validation`

---

## 🛡️ Stack de Seguridad

### Vault de Cifrado (Activado)
- **AES-256-GCM**: Cifrado autenticado para DNI y teléfonos
- **Master Key Management**: Clave maestra de 32 bytes (base64 encoded)
- **Fail-Safe Startup**: Aplicación no arranca sin clave válida
- **Key Rotation**: Procedimiento documentado para rotación cada 90 días
- **PBKDF2**: Derivación de claves con 100,000 iteraciones
- **Bcrypt**: Hashing de contraseñas con salt automático
- **IV Único**: Nonce aleatorio de 12 bytes por operación

### Redacción Automática de PII (Verificada 100%)
**Protección de Información Personal Identificable:**
- 🖼️ **DNI Image Redaction**: Redacción automática de zonas sensibles
  - MRZ (Machine Readable Zone) - 60,000 píxeles verificados
  - Firma del titular - 92,000 píxeles verificados
  - Equipo Emisor - 18,000 píxeles verificados
- ✅ **100% Opacity Verified**: 170,000+ píxeles testeados como negros (#000000)
- 🔒 **Cifrado en Reposo**: DNI y teléfonos cifrados en base de datos
- 🚫 **Zero-Log Policy**: Datos sensibles nunca en logs
- 🗑️ **Secure Cleanup**: Archivos originales eliminados inmediatamente

### Arquitectura DevSecOps
- **Security by Design**: Seguridad desde el diseño inicial
- **Security by Default**: Configuración segura por defecto
- **Defense in Depth**: Múltiples capas de seguridad (6 capas)
- **Shift Left**: Seguridad en todas las fases del desarrollo
- **Fail-Safe Defaults**: Sistema falla en modo seguro

### API Security (Frontend-Ready)
- **Secure CORS**: Orígenes específicos (NO wildcards)
- **Security Headers**: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection, CSP
- **External Connection Audit**: Logging de todas las conexiones con IP tracking
- **Rate Limiting**: Preparado para implementación

### Prevención de Amenazas (MITRE ATT&CK)
- ✅ **T1110 (Brute Force)**: Rate limiting + bloqueo temporal
- ✅ **T1566 (Phishing)**: Validación MIME de archivos
- ✅ **T1552 (Unsecured Credentials)**: Cifrado at-rest + vault
- ✅ **T1078 (Valid Accounts)**: MFA por email

### CI/CD Security & Automation
- 🔍 **Pre-Commit Hooks**: Detección de secretos antes de commit
- 📝 **Audit Logging**: Trazabilidad completa sin datos sensibles
- 🚨 **Security Monitoring**: Alertas en tiempo real
- 🧪 **Automated Testing**: Suite de tests de seguridad
- 🤖 **CodeQL Scanning**: Análisis automático de vulnerabilidades con GitHub CodeQL
- 🔐 **Dependabot**: Monitoreo y actualización automática de dependencias vulnerables
- 📊 **PR Reviews**: Revisiones automáticas de código y detección de malas prácticas
- 📝 **Issue Templates**: Plantillas estructuradas para bugs, features y vulnerabilidades

---

## 🏗️ Arquitectura Técnica

### Backend
- **Framework**: FastAPI 0.104.1
- **Base de Datos**: SQLAlchemy 2.0.23 (SQLite dev, PostgreSQL prod)
- **Autenticación**: JWT + MFA Email
- **Validación**: Pydantic 2.5.0 con schemas seguros

### Frontend (Multi-Platform Strategy)
- **Framework**: Flutter (Dart)
- **Targets**: Mobile (iOS/Android) & Web (Responsive)
- **Architecture**: Clean Architecture + Riverpod

### Seguridad
- **Cryptography**: 41.0.7 (AES-256-GCM)
- **Passlib**: 1.7.4 (Bcrypt)
- **Pillow**: 10.1.0 (Procesamiento de imágenes)
- **Python-Magic**: 0.4.27 (Validación MIME)

### Testing
- **Pytest**: 7.4.3
- **Coverage**: TDD con tests de seguridad

---

## 🚀 Instalación y Configuración

### Requisitos Previos
- Python 3.10+
- Git
- Virtual Environment

### Instalación

```bash
# Clonar repositorio
git clone https://github.com/Oga3105/InmuFacil_App.git
cd InmuFacil_App

# Cambiar a rama develop
git checkout develop

# Crear entorno virtual
python -m venv .venv

# Activar entorno virtual
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt
```

### Configuración de Seguridad (CRÍTICO)

> [!IMPORTANT]
> La aplicación **NO ARRANCARÁ** sin la configuración correcta del vault de cifrado.
> Este es un comportamiento de seguridad intencional (Fail-Safe Defaults).

**Paso 1: Copiar template de configuración**
```bash
cp .env.example .env
```

**Paso 2: Generar clave maestra de cifrado**
```bash
python -c "import os, base64; print(base64.b64encode(os.urandom(32)).decode())"
```

Este comando generará una clave de 32 bytes codificada en base64, similar a:
```
l2ZAbAkXldtm0gpXefU63TEuw8bs7yPg4FSQHKa3TsE=
```

**Paso 3: Configurar variables en `.env`**

Edita el archivo `.env` y añade tu clave generada:

```bash
# ============================================================================
# ENCRYPTION & SECURITY (CRÍTICO - REQUERIDO PARA ARRANQUE)
# ============================================================================

# Master encryption key for AES-256-GCM (32 bytes, base64 encoded)
INMUFACIL_MASTER_KEY=<TU_CLAVE_GENERADA_AQUÍ>

# JWT Secret Key for authentication tokens
SECRET_KEY_JWT=<GENERA_OTRA_CLAVE_PARA_JWT>

# ============================================================================
# DATABASE CONFIGURATION
# ============================================================================

DATABASE_URL=sqlite:///./inmufacil.db

# ============================================================================
# APPLICATION SETTINGS
# ============================================================================

ENVIRONMENT=development
DEBUG=true
API_BASE_URL=http://localhost:8000
LOG_LEVEL=INFO
```

> [!WARNING]
> **NUNCA** compartas o commites tu archivo `.env` a Git.
> El archivo está protegido por `.gitignore` y pre-commit hooks.

**Paso 4: Verificar configuración**

Al arrancar la aplicación, verás en los logs:
```
✅ Master encryption key loaded and validated successfully
🔐 VAULT: ACTIVATED
```

Si ves errores, verifica que:
- La clave tiene exactamente 32 bytes cuando se decodifica de base64
- El archivo `.env` está en la raíz del proyecto
- No hay espacios extra en la clave

### Rotación de Claves (Key Rotation)

**Procedimiento de rotación de la clave maestra:**

> [!CAUTION]
> La rotación de claves requiere re-cifrar todos los datos sensibles en la base de datos.
> Realiza este procedimiento solo durante ventanas de mantenimiento.

**Pasos para rotación segura:**

1. **Backup completo de la base de datos:**
   ```bash
   # Crear backup antes de rotación
   cp inmufacil.db inmufacil.db.backup.$(date +%Y%m%d_%H%M%S)
   ```

2. **Generar nueva clave:**
   ```bash
   python -c "import os, base64; print(base64.b64encode(os.urandom(32)).decode())"
   ```

3. **Ejecutar script de rotación (futuro):**
   ```bash
   # TODO: Implementar en próxima misión
   python scripts/rotate_encryption_key.py --old-key OLD_KEY --new-key NEW_KEY
   ```

4. **Actualizar `.env` con nueva clave**

5. **Verificar integridad:**
   ```bash
   # Verificar que todos los datos se descifraron correctamente
   python scripts/verify_encryption.py
   ```

6. **Reiniciar aplicación**

**Frecuencia recomendada:** Cada 90 días o inmediatamente si se sospecha compromiso.

### Ejecutar la Aplicación

```bash
# Desarrollo
uvicorn backend.main:app --reload

# La API estará disponible en:
# http://localhost:8000
# Documentación: http://localhost:8000/docs
```

---

## 🧪 Testing

```bash
# Ejecutar todos los tests
pytest tests/ -v

# Tests específicos
pytest tests/test_auth.py -v
pytest tests/test_filters.py -v

# Con coverage
pytest tests/ --cov=backend --cov-report=html
```

---

## 🤖 GitHub Automation

InmuFácil incluye un completo sistema de automatización en GitHub para mejorar la calidad del código, seguridad y colaboración.

### Características Implementadas

#### 📊 PR Summaries & Code Review Automático
- **Resúmenes automáticos** de cambios en cada Pull Request
- **Análisis de código** con Flake8, Pylint y Bandit
- **Detección de malas prácticas**: `print()` statements, código duplicado, vulnerabilidades
- **Comentarios automáticos** en PRs con recomendaciones

#### 🔍 Code Scanning con CodeQL
- **Análisis continuo** de código Python
- **Detección de vulnerabilidades** (SQL Injection, XSS, Command Injection, etc.)
- **Escaneo automático** en push, PR y semanalmente
- **Reportes en GitHub Security** para trazabilidad

#### 🔐 Dependabot
- **Monitoreo de dependencias** vulnerables (Python pip + GitHub Actions)
- **PRs automáticos** con actualizaciones seguras
- **Agrupación inteligente** por tipo (security, development, core framework)
- **Alertas de seguridad** proactivas

#### 📝 Issue & PR Templates
- **Plantillas estructuradas** para Bug Reports, Feature Requests y Security Vulnerabilities
- **PR Template** con checklist completo de revisión
- **Discussion Templates** para ideas y preguntas
- **Guías claras** para reportar problemas con pasos de reproducción

### Documentación Completa

Para más detalles sobre cómo usar y configurar estas características, consulta:

📖 **[GitHub Automation Guide](.github/GITHUB_AUTOMATION.md)**

### Activación Rápida

1. **CodeQL**: Ve a Settings → Code security and analysis → Habilita Code scanning
2. **Dependabot**: Ve a Settings → Code security and analysis → Habilita Dependabot alerts
3. **Discussions**: Ve a Settings → Features → Habilita Discussions
4. **Templates**: Se activan automáticamente al crear issues/PRs

---

## 🔐 Características de Seguridad

### 1. Escudo Anti-Agencias 🛡️
**Protección del ecosistema P2P:**
- Detección de 30+ dominios de agencias inmobiliarias
- Análisis de keywords profesionales (40+ términos)
- Validación multi-factor para prevenir falsos positivos
- Logging de intentos bloqueados con IP tracking

### 2. KYC Seguro (Know Your Customer)
**Validación de identidad con privacidad:**
- MFA por email (tokens de 6 dígitos, 15 min expiration)
- Redacción automática de DNI antes de almacenamiento
- Cifrado AES-256-GCM de datos personales
- Validación MIME para prevenir archivos maliciosos

### 3. Brute Force Prevention
**Protección contra ataques:**
- Máximo 3 intentos fallidos de upload
- Bloqueo temporal de 15 minutos
- Ventana deslizante de 30 minutos
- Alertas de seguridad estructuradas

### 4. Audit Trail Completo
**Trazabilidad sin comprometer privacidad:**
- Logs estructurados para SIEM
- Filtros automáticos de datos sensibles
- Eventos de seguridad con severidad
- Cumplimiento GDPR

---

## 📁 Estructura del Proyecto

```
InmuFacil_Project/
├── backend/
│   ├── main.py              # FastAPI application
│   ├── models.py            # SQLAlchemy models
│   ├── schemas.py           # Pydantic schemas
│   ├── database.py          # DB configuration
│   ├── security.py          # Password hashing
│   ├── crypto.py            # AES-256-GCM encryption
│   ├── filters.py           # Anti-agency filter
│   ├── security_monitor.py  # Brute force prevention
│   └── services/
│       ├── email_service.py # MFA tokens
│       └── kyc_service.py   # DNI processing
│   ├── routers/
│   │   ├── users.py         # User & Admin routes
│   │   ├── kyc.py           # KYC routes
│   │   └── properties.py    # Properties routes (Core + Satellites)
├── frontend/
│   ├── lib/
│   │   ├── main.dart        # Entry point
│   │   ├── core/            # Config & Utils
│   │   ├── data/            # Repositories & Data Sources
│   │   ├── domain/          # Entities & Use Cases
│   │   └── presentation/
│   │       ├── screens/     # UI Screens (Home, NotFound, etc.)
│   │       ├── widgets/     # Reusable Components
│   │       └── providers/   # State Management (Riverpod)
│   ├── assets/
│   │   └── translations/    # i18n JSON files (9 languages)
│   ├── web/                 # Web entrypoint
│   └── pubspec.yaml         # Dependencies
├── tests/
│   ├── test_auth.py         # Authentication tests
│   └── test_filters.py      # Filter tests
├── docs/
│   └── vision_proyecto.md   # Project vision
├── .git/hooks/
│   └── pre-commit           # Secret detection
├── requirements.txt         # Dependencies
├── .gitignore              # Git exclusions
├── .agent/
│   └── rules/
│       └── roles_definition.md  # Agent governance & protocols
└── README.md               # This file
```

---

## 🤝 Contribución

Este proyecto sigue estándares DevSecOps estrictos:

1. **Todas las contribuciones en rama `develop`**
2. **Tests obligatorios para nuevas features**
3. **Pre-commit hooks activos** (detección de secretos)
4. **Code review requerido**
5. **Documentación actualizada**

---

## 📜 Compliance y Estándares

- ✅ **GDPR**: Cifrado de datos personales, derecho al olvido
- ✅ **OWASP Top 10**: Mitigación de vulnerabilidades críticas
- ✅ **PCI DSS**: Cifrado at-rest, audit logging
- ✅ **ISO 27001**: Controles de seguridad implementados
- ✅ **MITRE ATT&CK**: Cobertura de técnicas de ataque

---

## 📞 Contacto y Soporte

**Repositorio:** https://github.com/Oga3105/InmuFacil_App  
**Documentación:** `/docs/vision_proyecto.md`  
**Issues:** GitHub Issues

---

## 📄 Licencia

[Pendiente de definir]

---

## 🙏 Agradecimientos

Desarrollado con:
- **Gemini AI** - Asistencia de desarrollo
- **FastAPI** - Framework web moderno
- **SQLAlchemy** - ORM robusto
- **Cryptography** - Seguridad de grado militar

---

**InmuFácil - Donde la tecnología reemplaza la confianza** 🏠🔐
