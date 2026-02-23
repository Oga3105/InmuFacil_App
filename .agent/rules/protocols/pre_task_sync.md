# PROTOCOLO: Pre-Task Sync Ritual

**Version:** 1.0
**Fecha:** 2026-02-23
**Responsable:** @DevOps
**Trigger:** Antes de crear cualquier rama nueva o empezar cualquier tarea que implique codigo.

---

## OBJETIVO

Garantizar que toda rama nueva parte desde `develop` actualizado. Previene conflictos heredados y divergencia silenciosa con el remoto.

---

## FLUJO OBLIGATORIO

```bash
# PASO 1: Verificar estado del arbol de trabajo
git status
```

**Si hay cambios sin commitear:**
```bash
git stash push -m "WIP: <descripcion breve>"
# Registrar internamente que se hizo stash para recuperarlo en paso 4
```

**Si el arbol esta limpio:** continuar al paso 2.

```bash
# PASO 2: Sincronizar con remoto
git fetch origin

# PASO 3: Actualizar develop local
git checkout develop
git pull --rebase origin develop
```

**Si el rebase falla:** DETENER. Notificar al usuario con el mensaje exacto de conflicto. No resolver conflictos no generados por el agente de forma autonoma.

```bash
# PASO 4: Restaurar trabajo si habia stash
git stash pop
```

**Si `stash pop` genera conflictos:** DETENER. Notificar al usuario.

```bash
# PASO 5: Verificar que la rama no existe ya
git branch -a | grep "<nombre-rama-planeada>"
```

**Si la rama ya existe en remoto:** preguntar al usuario si debe continuar desde esa rama o crear una nueva.

```bash
# PASO 6: Crear rama (solo tras completar pasos 1-5 sin errores)
git checkout -b <tipo>/<descripcion-corta>
```

---

## NAMING DE RAMAS

| Tipo de cambio | Prefijo | Ejemplo |
|---|---|---|
| Nueva funcionalidad | `feature/` | `feature/kyc-document-upload` |
| Correccion de bug | `fix/` | `fix/map-polygon-zoom` |
| Refactor sin cambio logico | `chore/` | `chore/extract-auth-service` |
| Solo documentacion | `docs/` | `docs/adr-015-jwt-rotation` |
| Fix critico en produccion | `hotfix/` | `hotfix/login-500-error` |

**Reglas de naming:**
- Minusculas y guiones. Sin espacios ni caracteres especiales.
- Descripcion corta pero clara (2-4 palabras).
- Nunca trabajar directamente en `develop` o `main` para cambios mayores.

---

## DECLARACION DE INTENCIONES

Antes de ejecutar el flujo, @DevOps declara al usuario el plan:

```
Plan de Accion Git:
  Tipo:    feat
  Rama:    feature/kyc-document-upload
  Base:    develop (sincronizado)
  Accion:  Pre-Task Sync -> Codificar -> Pre-Commit Gate -> Pre-PR Sync -> PR
```

---

## REGLA ANTE CONFLICTO

DETENER ejecucion completa. No resolver conflictos no generados por el agente. Notificar al usuario con:
- Nombre del archivo en conflicto
- Tipo de conflicto (merge vs rebase)
- Contexto de que ramas divergen
