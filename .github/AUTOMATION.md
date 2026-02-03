# Automatización de GitHub - InmuFácil

## 📋 Descripción General

Este documento describe la configuración de automatización implementada en el repositorio de InmuFácil para mejorar la calidad del código, seguridad y flujo de trabajo del equipo.

---

## 🔒 CodeQL - Análisis de Seguridad

**Archivo:** `.github/workflows/codeql-analysis.yml`

### Características:
- **Lenguaje:** Python (backend)
- **Frecuencia:** 
  - En cada push a `develop` y `main`
  - En cada Pull Request
  - Semanalmente (lunes a las 2 AM)
- **Queries:** `security-extended` y `security-and-quality`

### Qué Detecta:
- Inyección SQL
- Vulnerabilidades de autenticación
- Exposición de datos sensibles
- Configuraciones inseguras
- Uso de APIs deprecadas

---

## 📦 Dependabot - Actualizaciones Automáticas

**Archivo:** `.github/dependabot.yml`

### Ecosistemas Monitoreados:

#### 1. Backend Python (`pip`)
- **Directorio:** `/`
- **Frecuencia:** Semanal (lunes 9:00 AM)
- **Límite:** 5 PRs abiertas simultáneamente
- **Labels:** `dependencies`, `backend`, `python`

#### 2. Frontend Flutter (`pub`)
- **Directorio:** `/frontend`
- **Frecuencia:** Semanal (lunes 9:00 AM)
- **Límite:** 5 PRs abiertas simultáneamente
- **Labels:** `dependencies`, `frontend`, `flutter`

#### 3. GitHub Actions
- **Directorio:** `/`
- **Frecuencia:** Semanal (lunes 9:00 AM)
- **Límite:** 3 PRs abiertas simultáneamente
- **Labels:** `dependencies`, `github-actions`

### Configuración:
- **Reviewer:** @Oga3105
- **Assignee:** @Oga3105
- **Commit prefix:** `chore(deps):`

---

## 📝 Templates de Issues

### 1. Reporte de Bug
**Archivo:** `.github/ISSUE_TEMPLATE/bug_report.yml`

**Campos:**
- Descripción del bug
- Pasos para reproducir
- Comportamiento esperado vs actual
- Componente afectado
- Severidad (Crítico/Alto/Medio/Bajo)
- Entorno (OS, Python, Flutter)
- Logs/Errores
- Capturas de pantalla
- Checkbox de seguridad

**Labels:** `bug`, `needs-triage`

### 2. Solicitud de Feature
**Archivo:** `.github/ISSUE_TEMPLATE/feature_request.yml`

**Campos:**
- Problema a resolver
- Solución propuesta
- Componente
- Prioridad (Crítica/Alta/Media/Baja)
- Alternativas consideradas
- Mockups/Diseños
- Impacto (checkboxes)

**Labels:** `enhancement`, `needs-review`

### 3. Reporte de Vulnerabilidad
**Archivo:** `.github/ISSUE_TEMPLATE/vulnerability.yml`

**Campos:**
- Descripción de la vulnerabilidad
- Tipo (SQL Injection, XSS, CSRF, etc.)
- Severidad CVSS (Crítica/Alta/Media/Baja)
- Impacto
- Pasos para reproducir
- Mitigación sugerida
- Componentes afectados
- Compromiso de divulgación responsable

**Labels:** `security`, `critical`

### 4. Configuración
**Archivo:** `.github/ISSUE_TEMPLATE/config.yml`

**Enlaces:**
- Documentación
- Discusiones
- Reporte de seguridad privado

---

## 🔄 Template de Pull Request

**Archivo:** `.github/PULL_REQUEST_TEMPLATE.md`

### Secciones:

#### 1. Descripción
Breve descripción de los cambios

#### 2. Tipo de Cambio
- Bug fix
- Nueva funcionalidad
- Breaking change
- Documentación
- Refactoring
- Performance
- Seguridad
- Tests

#### 3. Issues Relacionados
Enlaces a issues que resuelve

#### 4. Checklist General
- Guías de estilo
- Auto-revisión
- Comentarios en código complejo
- Documentación actualizada
- Sin warnings
- Tests añadidos
- Tests pasando

#### 5. Checklist Backend
- `requirements.txt` actualizado
- `pytest` pasando
- Sin secretos hardcodeados
- Validación de PII
- Modelos de BD actualizados
- Endpoints probados

#### 6. Checklist Frontend
- `pubspec.yaml` actualizado
- `flutter test` pasando
- UI responsive
- Probado en debug y release
- Clean Architecture seguida

#### 7. Checklist Seguridad
- Sin secretos en código
- Datos sensibles encriptados
- Inputs validados
- Vulnerabilidades consideradas
- Dependencias actualizadas

#### 8. Checklist Git Flow
- Rama actualizada con develop
- Convención de commits seguida
- Rama en remoto
- CI/CD pasando

#### 9. Pruebas Realizadas
Descripción de tests ejecutados

#### 10. Screenshots/Recordings
Capturas o grabaciones si aplica

#### 11. Contexto TFM
Contribución al Trabajo Fin de Máster

---

## 🚀 Beneficios

### Seguridad
- ✅ Detección automática de vulnerabilidades
- ✅ Actualizaciones de seguridad automáticas
- ✅ Proceso estructurado para reportar vulnerabilidades

### Calidad
- ✅ Análisis estático de código
- ✅ Templates estandarizados
- ✅ Checklists exhaustivos en PRs

### Productividad
- ✅ Dependencias siempre actualizadas
- ✅ Proceso de revisión estructurado
- ✅ Menos tiempo en tareas repetitivas

### Documentación
- ✅ Historial claro de cambios
- ✅ Issues bien documentados
- ✅ PRs con contexto completo

---

## 📊 Métricas y Monitoreo

### CodeQL
- Ver resultados en: `Security` → `Code scanning alerts`
- Frecuencia: Semanal + en cada PR

### Dependabot
- Ver PRs en: `Pull requests` con label `dependencies`
- Revisar alertas en: `Security` → `Dependabot alerts`

### Issues y PRs
- Filtrar por labels para organizar trabajo
- Usar milestones para agrupar por Hitos

---

## 🎓 Contexto TFM

Esta automatización demuestra:
- **DevSecOps:** Seguridad integrada en el ciclo de desarrollo
- **CI/CD:** Integración y despliegue continuos
- **Buenas Prácticas:** Uso de herramientas estándar de la industria
- **Calidad:** Procesos estructurados y documentados

---

## 🔗 Referencias

- [CodeQL Documentation](https://codeql.github.com/docs/)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [GitHub Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests)
- [CVSS Scoring](https://www.first.org/cvss/)
