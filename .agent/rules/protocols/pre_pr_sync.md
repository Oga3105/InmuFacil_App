# PROTOCOLO: Pre-PR Sync

**Version:** 1.0
**Fecha:** 2026-02-23
**Responsable:** @DevOps
**Trigger:** Antes de abrir cualquier Pull Request hacia `develop` o `main`.

---

## OBJETIVO

Garantizar que el PR llega sin conflictos, con la feature branch actualizada sobre la ultima version de `develop`, y con el historial limpio. Previene el "conflicto sorpresa" en code review.

---

## FLUJO OBLIGATORIO

```bash
# PASO 1: Actualizar develop local
git fetch origin
git checkout develop
git pull --rebase origin develop

# PASO 2: Rebase de la feature sobre develop actualizado
git checkout <rama-feature>
git rebase origin/develop
```

**Si hay conflictos en el rebase:** DETENER. Notificar al usuario con:
- Lista exacta de archivos en conflicto
- Descripcion de que cambios divergen
- No resolver conflictos estructurales de forma autonoma

```bash
# PASO 3: Ejecutar Pre-Commit Gate completo post-rebase (ver pre_commit_gate.md)
# El rebase puede haber introducido cambios que requieren re-validacion

# PASO 4: Push de la rama actualizada al remoto
git push --force-with-lease origin <rama-feature>
# NUNCA: git push --force
# SIEMPRE: git push --force-with-lease (protege contra sobrescribir trabajo ajeno)

# PASO 5: Verificar que la rama existe en el remoto antes de crear PR
git ls-remote --heads origin <rama-feature>
```

**Si la rama no existe en remoto:** ejecutar `git push -u origin <rama-feature>` sin `--force-with-lease`.

```bash
# PASO 6: Crear PR
gh pr create \
  --title "<tipo>(<scope>): descripcion breve" \
  --body "$(cat <<'PREOF'
## Descripcion
[Que hace este PR y por que es necesario]

## Cambios introducidos
- [ ] cambio 1
- [ ] cambio 2

## Tests
- [ ] Tests unitarios pasando (pytest / flutter test)
- [ ] flutter analyze limpio (cero warnings)
- [ ] ruff check limpio (cero errores)
- [ ] Cobertura >= 80%

## Checklist de Seguridad (@Shield)
- [ ] Sin secretos hardcodeados en el codigo
- [ ] PII manejado correctamente (cifrado/redactado)
- [ ] RBAC verificado en endpoints nuevos
- [ ] Sin vulnerabilidades OWASP evidentes

## Debate Arquitectonico
[Resumen del debate si aplico, o "N/A — cambio trivial"]
PREOF
)"
```

---

## CRITERIOS DE APROBACION DE PR

El PR solo puede mergearse si todos los agentes verifican su checklist:

**@DevOps verifica:**
- [ ] Rama existe en remoto antes del merge
- [ ] Commits atomicos y con formato correcto
- [ ] Sin conflictos con develop (rebase completado)
- [ ] Pre-Commit Gate paso en verde

**@Shield verifica:**
- [ ] Sin secretos hardcodeados
- [ ] PII manejado correctamente
- [ ] Sin vulnerabilidades evidentes
- [ ] Audit logging presente para datos sensibles

**@Jules verifica:**
- [ ] Tests pasando (backend + frontend)
- [ ] Cobertura adecuada (>= 80% backend)
- [ ] Sin regresiones introducidas
- [ ] Nuevo codigo tiene tests asociados

**@Architect verifica:**
- [ ] Arquitectura consistente con el resto del proyecto
- [ ] Sin deuda tecnica innecesaria introducida
- [ ] Documentacion actualizada (`scratchpad.md`, `task.md`, ADRs si aplica)
- [ ] `roles_definition.md` sincronizado si se crearon nuevos archivos en `.agent/rules/`

---

## METODO DE MERGE

```bash
# Siempre --no-ff para preservar historia del proyecto
git checkout develop
git merge --no-ff <rama-feature>
git push origin develop

# Limpieza: solo rama local (preservar remota para TFM)
git branch -d <rama-feature>
# NO ejecutar: git push origin --delete <rama-feature>
```

---

## POLITICA TFM — RAMAS REMOTAS

PRESERVAR todas las ramas remotas sin excepcion.
Cada rama es evidencia de desarrollo iterativo para evaluacion academica.
Solo eliminar ramas locales obsoletas. Nunca las remotas.
