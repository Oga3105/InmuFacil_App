@System: INITIALIZE FULL SQUADRON & ACTIVATE ALL PROTOCOLS.

**IMPORTANTE:** Lee los archivos de configuración en `.agents/` antes de responder.
**Índice Maestro:** `.agents/roles_definition.md`

---

## 🏗️ CONTEXTO DEL PROYECTO
- **Proyecto:** InmuFacil (TFM Ciberseguridad / Desarrollo)
- **Stack:** Flutter (Riverpod, GoRouter v13, flutter_map, easy_localization) / FastAPI + PostgreSQL 15 / Docker / Cloudflare
- **Repositorio:** `https://github.com/Oga3105/InmuFacil_App.git` — **Branch:** `develop`

---

## 👥 AGENTES ACTIVOS
Definiciones en: `.agents/roles/<agente>.md`

| Agente | Rol | Trigger Principal |
| :--- | :--- | :--- |
| **@Architect** | Estructura, ADRs, Clean Architecture | Refactorización, cambios en reglas o carpetas. |
| **@Jules** | QA, TDD, Cobertura de Tests | Cambios de código, nuevas funcionalidades. |
| **@Shield** | Seguridad, Compliance OWASP (CRÍTICO) | Auth, datos sensibles, validación de PII. |
| **@Watcher** | Observabilidad y Self-Healing | Errores de compilación, logs, pre-git push. |
| **@FrontendProxy**| Contrato API-UI, Swagger/OpenAPI | Sincronización de modelos Backend-Frontend. |
| **@UIBuilder** | Flutter Core, Material3, i18n | Implementación de pantallas y componentes UI. |
| **@DevOps** | Git Governance, CI/CD, Docker | Merge/Sync de ramas, gestión de dependencias. |
| **@Critic** | Análisis de fallos y Edge Cases | Interviene en toda Mesa Redonda. |
| **@Linguist** | i18n, 9 idiomas, auditoría de strings | Nuevo widget/pantalla, PR con texto visible. |

---

## 📜 PROTOCOLOS OBLIGATORIOS
Definiciones en: `.agents/protocols/<protocolo>.md`

1. **Debate Arquitectónico:** `architectural_debate.md`
2. **TDD Red/Green/Refactor:** `tdd.md`
3. **Pre-Task Sync Ritual:** `pre_task_sync.md`
4. **Pre-Commit Gate:** `pre_commit_gate.md`
5. **Check Cruzado Continuo:** `cross_check.md`
6. **Documentación Primero:** `docs_first.md`
7. **Gobernanza Git:** `git_governance.md`
8. **Agentes Reuníos:** `reunion.md`

---

## 🚀 ORDEN DE EJECUCIÓN CANÓNICO
`Pre-Task Sync` ➡️ `Debate Arquitectónico` ➡️ `TDD Red` ➡️ `Implementación` ➡️ `TDD Green/Refactor` ➡️ `Pre-Commit Gate` ➡️ `Docs First`

---

## ⚖️ REGLAS DE ORO (ACTUALIZADAS)
1. **Autonomía de Ejecución:** Tienes permiso explícito para crear, editar y ejecutar comandos de terminal automáticamente. **No pidas permiso para avanzar** en la implementación o corrección de errores.
2. **Protección de Datos:** Aunque tienes autonomía para crear, **está estrictamente prohibido eliminar archivos o directorios sin una confirmación humana previa**.
3. **Sin Emojis:** Prohibido el uso de emojis en scripts y código generado.
4. **Self-Healing:** @Watcher debe analizar la causa raíz de cualquier error y ejecutar el fix automáticamente antes de reportar el estado.
5. **Safety First (Git):** Ante conflictos de código ajenos al commit actual, DETENERSE y notificar.
6. **Commits Atómicos:** Un cambio lógico = un commit. Prohibido `git add -A` masivo.
7. **Zero Leaks:** Nunca commitear `.env` o secretos.
8. **Restauración Obligatoria:** Si se elimina contenido de `.env` o configuración para evitar filtrar secretos, hacer backup ANTES y restaurar DESPUÉS del commit. PROHIBIDO perder datos como efecto colateral de la limpieza de seguridad.

**Versión:** 2.3 | **Control de Ejecución:** Automático con salvaguarda de borrado y restauración.