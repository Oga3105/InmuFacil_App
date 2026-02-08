# 🤖 Protocolo de Agentes Internos de InmuFácil
**Índice Maestro de Roles y Protocolos**

Este documento ha sido **MODULARIZADO** para mejorar la mantenibilidad y escalabilidad. A continuación se encuentran los enlaces a las definiciones específicas.

## 👥 ROLES DE AGENTES (`.agent/rules/roles/`)

| Agente | Rol Principal | Archivo de Definición |
| :--- | :--- | :--- |
| **@Architect** | Diseño y Calidad | [roles/architect.md](roles/architect.md) |
| **@Jules** | QA y Testing | [roles/jules.md](roles/jules.md) |
| **@Shield** | Seguridad (DevSecOps) | [roles/shield.md](roles/shield.md) |
| **@Watcher** | Observabilidad | [roles/watcher.md](roles/watcher.md) |
| **@FrontendProxy** | Interfaz UI/API | [roles/frontend_proxy.md](roles/frontend_proxy.md) |
| **@DevOps** | Despliegue y Git | [roles/devops.md](roles/devops.md) |
| **@UIBuilder** | Implementación Flutter | [roles/ui_builder.md](roles/ui_builder.md) |

---

## 📜 PROTOCOLOS OPERATIVOS (`.agent/rules/protocols/`)

| Protocolo | Descripción | Archivo |
| :--- | :--- | :--- |
| **Gobernanza Git** | Flujo de ramas, commits y PRs | [protocols/git_governance.md](protocols/git_governance.md) |
| **"Agentes, reuníos"** | Protocolo de Salud General | [protocols/reunion.md](protocols/reunion.md) |
| **Check Cruzado** | Verificación entre agentes | [protocols/cross_check.md](protocols/cross_check.md) |
| **Docs First** | Política de documentación | [protocols/docs_first.md](protocols/docs_first.md) |

---

> *Este índice reemplaza al antiguo archivo monolítico de >12k caracteres. Para añadir un nuevo agente, cree un archivo en `roles/` y agréguelo a esta tabla.*
