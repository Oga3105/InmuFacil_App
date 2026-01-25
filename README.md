# InmuFácil 🏠🔐

**Plataforma P2P de Compraventa Inmobiliaria con Seguridad DevSecOps**

InmuFácil es una plataforma peer-to-peer que elimina intermediarios en las transacciones inmobiliarias, sustituyendo la confianza tradicional de las agencias por tecnología de cifrado de grado militar y validación de identidad automatizada.

---

## 🎯 Visión del Proyecto

**"Donde la tecnología reemplaza la confianza"**

InmuFácil permite que particulares compren y vendan propiedades directamente, sin agencias inmobiliarias, utilizando:
- **Gemini AI** para asistencia inteligente y validación
- **Cifrado AES-256-GCM** para protección de datos sensibles
- **Verificación KYC automatizada** con redacción de PII
- **Escudo Anti-Agencias** para mantener el ecosistema P2P puro

---

## 📊 Estado Actual del Proyecto

**Hito Actual:** 🔐 **Hito 2 - Validación de Identidad** ✅ COMPLETADO

**Progreso:**
- ✅ Hito 1: Estructura Base y Autenticación
- ✅ Hito 2: Validación de Identidad (KYC Seguro)
- ⏳ Hito 3: Activación de Bóveda (Próximo)
- 🔜 Hitos 4-15: En planificación

**Rama Activa:** `develop`  
**Último Commit:** `50a20b2 - feat: implementation of DevSecOps KYC flow with AES-256-GCM and image redaction`

---

## 🛡️ Stack de Seguridad

### Cifrado y Protección de Datos
- **AES-256-GCM**: Cifrado autenticado para DNI y teléfonos
- **PBKDF2**: Derivación de claves con 100,000 iteraciones
- **Bcrypt**: Hashing de contraseñas con salt automático
- **IV Único**: Nonce aleatorio de 12 bytes por operación

### Redacción Automática de PII
**Protección de Información Personal Identificable:**
- 🖼️ **DNI Image Redaction**: Redacción automática de zonas sensibles
  - MRZ (Machine Readable Zone)
  - Firma del titular
  - Equipo Emisor
- 🔒 **Cifrado en Reposo**: DNI y teléfonos cifrados en base de datos
- 🚫 **Zero-Log Policy**: Datos sensibles nunca en logs

### Arquitectura DevSecOps
- **Security by Design**: Seguridad desde el diseño inicial
- **Security by Default**: Configuración segura por defecto
- **Defense in Depth**: Múltiples capas de seguridad
- **Shift Left**: Seguridad en todas las fases del desarrollo

### Prevención de Amenazas (MITRE ATT&CK)
- ✅ **T1110 (Brute Force)**: Rate limiting + bloqueo temporal
- ✅ **T1566 (Phishing)**: Validación MIME de archivos
- ✅ **T1552 (Unsecured Credentials)**: Cifrado at-rest
- ✅ **T1078 (Valid Accounts)**: MFA por email

### CI/CD Security
- 🔍 **Pre-Commit Hooks**: Detección de secretos antes de commit
- 📝 **Audit Logging**: Trazabilidad completa sin datos sensibles
- 🚨 **Security Monitoring**: Alertas en tiempo real

---

## 🏗️ Arquitectura Técnica

### Backend
- **Framework**: FastAPI 0.104.1
- **Base de Datos**: SQLAlchemy 2.0.23 (SQLite dev, PostgreSQL prod)
- **Autenticación**: JWT + MFA Email
- **Validación**: Pydantic 2.5.0 con schemas seguros

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

### Configuración de Seguridad

**Variables de Entorno (.env):**
```bash
# CRÍTICO: Nunca commitear este archivo
ENCRYPTION_SECRET=your-super-secret-key-change-in-production
DATABASE_URL=sqlite:///./inmufacil.db
SECRET_KEY=your-jwt-secret-key
```

**⚠️ IMPORTANTE:** El archivo `.env` está protegido por `.gitignore` y pre-commit hooks.

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
├── tests/
│   ├── test_auth.py         # Authentication tests
│   └── test_filters.py      # Filter tests
├── docs/
│   └── vision_proyecto.md   # Project vision
├── .git/hooks/
│   └── pre-commit           # Secret detection
├── requirements.txt         # Dependencies
├── .gitignore              # Git exclusions
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
