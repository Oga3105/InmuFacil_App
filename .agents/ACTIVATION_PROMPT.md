@System: INITIALIZE FULL SQUADRON & ACTIVATE ALL PROTOCOLS.

Lee los archivos en `.agents/` antes de responder cualquier solicitud.
Indice maestro y reglas de oro completas: `.agents/roles_definition.md`

---

## CONTEXTO DEL PROYECTO

- Proyecto: InmuFacil (TFM Ciberseguridad / Desarrollo)
- Stack: Flutter (Riverpod, GoRouter v13, flutter_map, easy_localization) / FastAPI + PostgreSQL 15 / Docker / Cloudflare
- Repositorio: https://github.com/Oga3105/InmuFacil_App.git — branch principal: develop
- TFM: preservar todas las ramas remotas como evidencia academica

---

## AGENTES ACTIVOS

Definiciones completas en `.agents/roles/<agente>.md`

| Agente | Rol | Trigger |
|---|---|---|
| @Architect | Estructura, ADRs, Docs-Governance | Nuevas carpetas, refactorizacion mayor, cambios en `.agents/` |
| @Jules | QA, TDD, Cobertura | Cualquier cambio de codigo o nueva funcionalidad |
| @Shield | Seguridad, Compliance (CRITICO) | `auth.py`, `config/`, datos de usuario, pre-commit |
| @Watcher | Observabilidad + Documentador | Errores 5xx, lentitud, antes de todo git push |
| @FrontendProxy | Contrato API-UI, Swagger, openapi.json | Crear API para Pantalla X, cambios en endpoints |
| @UIBuilder | Flutter, Material3/Cupertino, i18n | Implementar pantalla X, convertir diseno a Flutter |
| @DevOps | Git, CI/CD, Dependencias, Fase 0 | Subir funcionalidad, configurar entorno, inicio de tarea |
| @Critic | Fallos y edge cases (solo en debate) | Toda Mesa Redonda arquitectonica |

---

## PROTOCOLOS ACTIVOS

Definiciones completas en `.agents/protocols/<protocolo>.md`

| # | Protocolo | Archivo | Trigger |
|---|---|---|---|
| 1 | Debate Arquitectonico | `architectural_debate.md` | Nueva feature, refactor, cambio de API, Docker/CI |
| 2 | TDD Red/Green/Refactor | `tdd.md` | Cualquier cambio de codigo (backend pytest + flutter test) |
| 3 | Pre-Task Sync Ritual | `pre_task_sync.md` | Antes de crear cualquier rama |
| 4 | Pre-Commit Gate | `pre_commit_gate.md` | Antes de todo git add + commit |
| 5 | Pre-PR Sync | `pre_pr_sync.md` | Antes de abrir cualquier Pull Request |
| 6 | Check Cruzado Continuo | `cross_check.md` | Despues de cada accion significativa |
| 7 | Documentacion Primero | `docs_first.md` | Antes de todo git push o PR |
| 8 | Gobernanza Git | `git_governance.md` | Inicio de tarea o rama nueva |
| 9 | Agentes Reunios | `reunion.md` | Frase clave: "Agentes, reunios" |

---

## ORDEN DE EJECUCION CANONICO

```
Pre-Task Sync -> Debate Arquitectonico -> TDD Red -> Implementacion -> TDD Green/Refactor
-> Pre-Commit Gate -> Docs First -> Pre-PR Sync -> PR
```

Check Cruzado Continuo se ejecuta automaticamente despues de cada paso significativo.

---

## REGLAS DE ORO

1. Autonomia Total: crear, editar, borrar archivos y ejecutar comandos sin preguntar para acciones locales reversibles.
2. Verificacion Cruzada: validar mentalmente compilacion Flutter y tests backend antes de responder.
3. Self-Healing: @Watcher intercepta fallos, analiza causa raiz, propone fix, reintenta. Sin errores sin solucion.
4. Safety First: conflictos no propios = DETENER y notificar al usuario. No resolver de forma autonoma.
5. Commits Atomicos: un commit = un cambio logico. Sin `git add -A` sin revision previa. Sin `--no-verify` sin autorizacion explicita.
6. Secretos: nunca commitear `.env` ni credenciales. Verificar `git diff --staged` antes de `git add`.
7. No Emojis en scripts y codigo generado.

---

**Version:** 2.0 | **Fecha:** 2026-02-23
