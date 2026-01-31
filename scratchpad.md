# Memoria del Proyecto InmuFácil
- **Estado Actual:** ✅ SINCRONIZADO - DOCUMENTACIÓN PÚBLICA AL DÍA
- **Repositorio Remoto:** https://github.com/Oga3105/InmuFacil_App.git
- **Rama Activa:** `develop` ⚡
- **Último Commit:** 6fba00e - docs: finalize professional README with security specifications
- **Verificación:** ✅ .env protegido | ✅ README actualizado | ✅ 0 commits pendientes
- **Misiones Completadas:** M1-M9 | **Próximo Hito:** 🎯 HITO 10 - Frontend App (Flutter)
- **Agentes:** Architect (✅ Activo), Jules (✅ Activo), Shield (✅ Activo), Watcher (✅ Activo), **FrontendProxy (🆕 Flutter/Mobile)**, **DevOps (✅ GitHub Actions)**

## Estrategia de Ramificación (Git Flow)
- **Rama Activa de Desarrollo:** `develop` ⚡
- **Rama de Producción Estable:** `main` 🔒
- **Política:** Todo desarrollo, testing y seguridad se ejecuta en `develop`. Solo versiones estables y validadas se fusionan a `main`.

## 📋 Estado de Misiones

### ✅ Misión 4: KYC Seguro - COMPLETADA Y AUDITADA
**Estado:** CONSOLIDADO EN GITHUB (Commit: 50a20b2)  
**Fecha Completado:** 2026-01-25  
**Auditoría:** ✅ Aprobada

**Entregables:**
- ✅ Cifrado AES-256-GCM con PBKDF2 (100,000 iteraciones)
- ✅ MFA Email con tokens de 6 dígitos (15 min expiration)
- ✅ Redacción automática de DNI (MRZ, Firma, Equipo Emisor)
- ✅ Validación MIME multi-capa
- ✅ Brute Force Prevention (MITRE T1110)
- ✅ Pre-commit hooks para detección de secretos
- ✅ Audit logging sin datos sensibles

**Compliance:**
- ✅ GDPR: Cifrado de datos personales
- ✅ OWASP Top 10: Mitigación completa
- ✅ PCI DSS: Cifrado at-rest, audit logging
- ✅ MITRE ATT&CK: T1110, T1566, T1552, T1078

### ✅ Misión 3: Escudo Anti-Agencias - COMPLETADA
**Estado:** ACTIVO Y OPERACIONAL  
**Entregables:**
- ✅ Filtro heurístico (30+ dominios, 40+ keywords)
- ✅ Validación multi-factor
- ✅ IP tracking y análisis de patrones
- ✅ 15+ tests de cobertura

### ✅ Misión 2: Modelos y Seguridad Base - COMPLETADA
**Entregables:**
- ✅ User model con SQLAlchemy
- ✅ Bcrypt password hashing
- ✅ Pydantic schemas con RLS
- ✅ Logging estructurado

### ✅ Misión 5: Vault Activation - COMPLETADA
**Estado:** CONSOLIDADO (Commit: e34b514)
**Entregables:**
- ✅ Master encryption key generada (32 bytes, base64)
- ✅ `backend/core/security.py` - AES-256-GCM encrypt/decrypt
- ✅ Fail-safe startup validation (app won't start without key)
- ✅ `.env.example` template creado
- ✅ Key rotation procedure documentado

### ✅ Misión 6: Security Breach Remediation - COMPLETADA
**Estado:** CONSOLIDADO (Commit: 2eb6971, f6389a7)
**Entregables:**
- ✅ `.env.example` sanitizado (real key removed)
- ✅ Local `.env` creado con real key (gitignored)
- ✅ AES-256-GCM verified (Galois/Counter Mode)
- ✅ Encryption test suite created

### ✅ Misión 7: Automated DNI Redaction - COMPLETADA
**Estado:** CONSOLIDADO (Commit: dcd867c, 724e0c1)
**Entregables:**
- ✅ `POST /auth/verify-identity` endpoint
- ✅ File hashing (SHA-256) for audit trail
- ✅ Secure cleanup with verification
- ✅ OCR simulation + encryption integration
- ✅ `tests/test_redaction.py` - 100% opacity verified (170,000+ pixels)

### ✅ Misión 8: API Frontend Integration - COMPLETADA
**Estado:** CONSOLIDADO (Commit: ff79d71)
**Entregables:**
- ✅ Secure CORS (specific origins only, no wildcards)
- ✅ Security headers (X-Content-Type-Options, X-Frame-Options, X-XSS-Protection, CSP)
- ✅ Enhanced Swagger documentation
- ✅ Improved `/health` endpoint (validates encryption + database)
- ✅ External connection audit logging

---

### ✅ Misión 9: Autenticación JWT - COMPLETADA
**Estado:** ACTIVO Y VERIFICADO (Tests Pass)
**Entregables:**
- ✅ Endpoint POST /auth/register con integración KYC
- ✅ Endpoint POST /auth/login con JWT generation
- ✅ Endpoint POST /auth/verify-email (MFA)
- [/] Endpoint POST /auth/upload-dni con redacción (Integrado en flujo)
- ✅ Endpoint POST /auth/request-password-reset
- ✅ Endpoint POST /auth/reset-password con MFA
- ✅ Middleware de autenticación JWT
- ✅ Tests de integración end-to-end (`tests/test_auth.py`)

### ✅ Misión 10 (Hito 10): Sistema de Tasación - COMPLETADA
**Estado:** ACTIVO Y VERIFICADO (Tests Pass)
**Entregables:**
- ✅ Modelo `PropertyValuation` (SQLAlchemy)
- ✅ Servicio `ValuationService` (Internal Algo + External Mock)
- ✅ Endpoint `POST /valuation` (Owner Only)
- ✅ Endpoint `GET /valuation` (History)
- ✅ Tests verificados (`tests/test_valuation.py`)

### ✅ Misión 11 (Hito 11): Sistema de Financiación - COMPLETADA
**Estado:** ACTIVO Y VERIFICADO (Tests Pass)
**Entregables:**
- ✅ Modelo `MortgageProfile` y `MortgageSimulation`
- ✅ Servicio `FinancingService` con Scoring de Solvencia
- ✅ Mock "Meta-Buscador": iAhorro, BBVA, Santander
- ✅ Rol `FINANCIERO` y asignación de asesores
- ✅ Tests verificados (`tests/test_financing.py`)

### ✅ Misión 12 (Hito 12): Generador de Contratos - COMPLETADA
**Estado:** CONSOLIDADO EN GITHUB (Merge a `develop`)
**Entregables:**
- ✅ Motor de Contratos con ReportLab
- ✅ Endpoint Seguro de Descarga (RBAC)
- ✅ Tests de Integración y Seguridad
- ✅ ADR 012 Documentado

### ✅ Refinamiento 12.5: Cuestionario Legal (Feedback Usuario)
**Estado:** COMPLETADO
- ✅ OCR de contrato aportado por usuario
- ✅ ADR 013 (Contratos Dinámicos)
- ✅ Schema `PropertyOffer.contract_data` (JSON)
- ✅ Endpoint `PUT /details` para cuestionario
- ✅ Endpoint `PUT /details` para cuestionario
- ✅ Generado PDF con cláusulas condicionales (Cuerpo Cierto, AML, etc.)

### ✅ Refinamiento 12.6: Contratos Personalizados e IA 🤖
**Estado:** COMPLETADO
- ✅ Subida de contratos propios (PDF/Word)
- ✅ Análisis de riesgos con IA (Simulado en Mock)
- ✅ **Legal:** Consentimiento expreso + Descarga de responsabilidad (Liability Waiver) guarda en DB.

### 📢 Protocolo: AGENTES REUNÍOS (Health Check)
Cuando se invoca sin objetivo específico, implica una revisión general:
- **@DevOps:** Git Status, archivos sin trackear, ramas limpias.
- **@Watcher:** Coherencia documental (`README.md`, `vision_proyecto.md`, `task.md` vs Realidad).
- **@Architect:** Limpieza de deuda técnica (scripts temporales, imports no usados).
- **@Shield:** Revisión de secretos o configs expuestas.


### Security by Design
**Filosofía:** La seguridad se considera desde el diseño inicial, no como añadido posterior.

**Implementaciones:**
- ✅ **Arquitectura Zero Trust**: Verificación en cada capa
- ✅ **Principio de Mínimo Privilegio**: Schemas Pydantic solo exponen datos necesarios
- ✅ **Defense in Depth**: 6 capas de seguridad (Perímetro, Identidad, Datos, Acceso, Monitoreo, Desarrollo)
- ✅ **Fail Secure**: Sistema falla en modo seguro (bloqueos, no exposición)

### Security by Default
**Filosofía:** Configuración segura out-of-the-box, sin requerir configuración adicional.

**Implementaciones:**
- ✅ **Cifrado Automático**: AES-256-GCM activado por defecto para DNI/teléfono
- ✅ **Logs Seguros**: Filtros automáticos de datos sensibles
- ✅ **MFA Obligatorio**: Email verification requerida antes de upload DNI
- ✅ **Rate Limiting**: Brute force prevention activo desde el inicio
- ✅ **Secrets Protection**: Pre-commit hooks activos automáticamente

### DevSecOps
**Filosofía:** Integración de seguridad en todo el ciclo de desarrollo.

**Implementaciones:**
- ✅ **Shift Left**: Seguridad desde el primer commit
- ✅ **Automated Testing**: Tests de seguridad en CI/CD
- ✅ **Code Review**: Revisión obligatoria antes de merge
- ✅ **Secret Scanning**: Pre-commit hooks detectan secretos
- ✅ **Audit Trail**: Logs completos de todas las operaciones
- ✅ **Continuous Monitoring**: Security monitor en tiempo real

---

## 🔐 Hito 2 - KYC Protegido (Misión 4 - DevSecOps)
- **Estado:** ✅ ACTIVO
- **Cifrado:** AES-256-GCM para DNI y teléfono
- **MFA:** Verificación email con tokens de 6 dígitos (15 min expiration)
- **Redacción DNI:** Automática (MRZ, Firma, Equipo Emisor)
- **Validación MIME:** Prevención de archivos maliciosos
- **Brute Force Prevention:** Bloqueo tras 3 intentos (MITRE T1110)
- **Pre-Commit Hook:** Detección de secretos en código
- **Audit Logging:** Sin datos sensibles (Security by Default)

## 🛡️ Escudo Anti-Inmo (Misión 3)
- **Estado:** ✅ ACTIVO
- **Dominios Bloqueados:** 30+ agencias inmobiliarias conocidas
- **Detección:** Email domain + Keywords profesionales
- **Prevención Falsos Positivos:** Multi-factor validation
- **Logging:** Alertas estructuradas con IP tracking
- **Cobertura Tests:** 15+ casos de prueba

## Archivos Desplegados - Misión 4 (DevSecOps)
### Security & Encryption (@Shield)
- ✅ `backend/crypto.py` - AES-256-GCM encryption/decryption con key derivation
- ✅ `backend/services/email_service.py` - MFA tokens con rate limiting
- ✅ `backend/models.py` - Campos cifrados y MFA en User model

### Secure Document Processing (@Jules)
- ✅ `backend/services/kyc_service.py` - Redacción DNI + MIME validation
- ✅ DNI Image Redaction: MRZ, Firma, Equipo Emisor zones

### Security Monitoring (@Watcher)
- ✅ `backend/security_monitor.py` - Brute force prevention + audit logging
- ✅ Sensitive data filter para logs (Security by Default)

### CI/CD Security (@Architect)
- ✅ `.git/hooks/pre-commit` - Secret detection hook
- ✅ `requirements.txt` - Dependencias: cryptography, Pillow, python-magic

## Archivos Desplegados - Misión 3
### Anti-Agency Filter
- ✅ `backend/filters.py` - Filtro heurístico anti-agencias (@Jules + @Shield)
- ✅ `tests/test_filters.py` - Suite de tests del filtro (@Jules)
- ✅ `backend/main.py` - Integración con logging y middleware (@Watcher + @Architect)

## Archivos Desplegados - Misión 2
### Backend Core
- ✅ `backend/models.py` - Modelo User con SQLAlchemy (@Jules)
- ✅ `backend/database.py` - Configuración de base de datos y sesiones
- ✅ `backend/security.py` - Hashing Bcrypt y verificación (@Shield)
- ✅ `backend/schemas.py` - Schemas Pydantic con RLS (@Shield)

### Testing & Dependencies
- ✅ `tests/test_auth.py` - Suite de tests TDD para autenticación (@Jules)
- ✅ `requirements.txt` - Dependencias del proyecto

### Documentación Base
- ✅ `docs/vision_proyecto.md` - Visión completa del proyecto con 15 hitos
- ✅ `.gitignore` - Configuración Python/FastAPI
- ✅ `scratchpad.md` - Memoria del proyecto

## Token Consumption Tracking (@Watcher)
### Misión 4 (DevSecOps)
- Crypto Implementation (AES-256-GCM): ~800 tokens
- Email Service (MFA): ~500 tokens
- KYC Service (Image Redaction): ~900 tokens
- Security Monitor (Brute Force): ~600 tokens
- Pre-Commit Hook: ~400 tokens
- **Misión 4 Total:** ~3,200 tokens

### Misión 3
- Filter Implementation: ~700 tokens
- Filter Tests: ~500 tokens
- Integration & Logging: ~400 tokens
- **Misión 3 Total:** ~1,600 tokens

### Misión 2
- Security Implementation: ~500 tokens
- Schema Definitions: ~400 tokens
- Logging Setup: ~300 tokens
- Test Implementation: ~600 tokens
- **Misión 2 Total:** ~1,800 tokens

### **Total Acumulado:** ~6,600 tokens

---

## 📢 Protocolos de Operación

### 🚨 Protocolo: "Agentes, reuníos"
**Trigger:** El usuario pronuncia la frase clave "Agentes, reuníos".
**Acción:** Todos los agentes deben detener su trabajo actual y realizar una revisión de sus responsabilidades.
**Objetivo:** Identificar tareas pendientes de mantenimiento, documentación, git, o limpieza que se hayan pasado por alto.

**Checklist por Agente:**
- **@Architect:** Revisar coherencia de ADRs, estructura de carpetas y deuda técnica.
- **@Jules:** Verificar tareas pendientes en `task.md`, estado de tests y cobertura.
- **@Shield:** Auditar logs recientes, verificar alertas de seguridad y secretos.
- **@Watcher:** Revisar estado de métricas, logs de auditoría y rendimiento.
- **@FrontendProxy:** Validar paridad API vs UI Mockups, necesidades de endpoints.
- **@DevOps:** Verificar estado de ramas git, commits pendientes, y pipelines.

**Salida Esperada:** Un reporte conciso de cada agente indicando "Sin tareas pendientes" o listando las acciones requeridas.

### 🔄 Protocolo: "Check Cruzado Continuo"
**Trigger:** Después de cada acción significativa (refactor, cleanup, feature).
**Acción:** El sistema debe evaluar automáticamente si la acción completada dispara responsabilidades en otros agentes.
**Ejemplo:**
- Si @Architect mueve archivos -> @DevOps debe preguntar por Commit/Push.
- Si @Jules crea código -> @Shield debe preguntar por revisión de seguridad.
**Objetivo:** Evitar silos y asegurar la integridad del ciclo de vida (Git, Docs, Tests).

### 📚 Protocolo: "Documentación Primero" (Docs First)
**Trigger:** Antes de cualquier `git push` o Pull Request.
**Regla de Oro:** **PROHIBIDO subir código sin actualizar su documentación asociada.**

**Flujo de Trabajo:**
1.  **Agente Implementador (@Jules/@Architect):** Termina el código y los tests.
2.  **Agente Documentador (@Watcher):**
    *   Actualiza `scratchpad.md` (Estado de Misión).
    *   Actualiza `task.md` (Checklists).
    *   Actualiza `ADRs` si hubo cambios de arquitectura.
    *   Actualiza `vision_proyecto.md` si cambió el alcance.
3.  **Agente DevOps (@DevOps):**
    *   Verifica que los docs han sido modificados.
    *   Ejecuta: `git add .`, `git commit`, `git push`.

### 🌳 Protocolo: Gestión de Ramas (Git Flow + PRs)
**Trigger:** Inicio de cualquier nueva tarea o feature.
**Responsable:** @DevOps

**Reglas de Actuación:**
1.  **Inicio:** NUNCA trabajar en `develop` directo.
    *   Comando: `git checkout -b feature/[nombre-tarea]`
2.  **Desarrollo:** Commits atómicos y frecuentes.
    *   Formato: `feat: implement logic for X`
3.  **Validación Local:**
    *   Ejecutar tests: `pytest` (Si ❌ -> Corregir).
4.  **Publicación (Pull Request):**
    *   Subir rama: `git push origin feature/[nombre-tarea]`
    *   **ACCIÓN MANUAL:** Crear Pull Request en GitHub.
5.  **Cierre (Post-Merge):**
    *   Tras fusión en GitHub:
    *   `git checkout develop`
    *   `git pull origin develop`
    *   `git branch -d feature/[nombre-tarea]`
