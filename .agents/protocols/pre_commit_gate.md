# PROTOCOLO: Pre-Commit Gate

**Version:** 1.0
**Fecha:** 2026-02-23
**Responsable:** @DevOps + @Shield + @Jules
**Trigger:** Antes de cualquier `git add` + `git commit` en codigo productivo.

---

## OBJETIVO

Garantizar que solo codigo limpio, testeado y sin secretos llega al historial de git. Un commit en git es permanente en la historia del proyecto.

---

## CHECKLIST OBLIGATORIO

Todos los puntos deben pasar. Si alguno falla: corregir antes de commitear.

### @Shield — Escaneo de Seguridad

```bash
# Revisar contenido del staging area antes de add
git diff --staged
```

- [ ] Staging area no contiene patrones de secretos: `API_KEY`, `SECRET`, `PASSWORD`, `TOKEN`, `private_key`, `client_secret`
- [ ] `.env` y variantes (`.env.local`, `.env.production`) NO estan en staging (`git diff --staged --name-only`)
- [ ] Sin credenciales hardcodeadas en ningun archivo staged
- [ ] Sin rutas absolutas del sistema local (ej: `/Users/nombre/`, `C:\Users\`)

**Si se detecta un secreto:** NO commitear. Eliminar del archivo, agregar al `.gitignore` si es necesario, limpiar del staging con `git reset HEAD <archivo>`.

**REGLA DE RESTAURACION OBLIGATORIA (Non-Negotiable):**
Si durante el proceso de commit se elimina o redacta contenido de `.env` u otros archivos de configuracion para evitar filtrar secretos, es OBLIGATORIO restaurar el contenido original inmediatamente despues del commit. Queda PROHIBIDO que cualquier dato se pierda de forma permanente como efecto colateral de la limpieza de seguridad. Flujo correcto:
1. Hacer backup del contenido antes de modificar: `cp .env .env.backup`
2. Limpiar el archivo para el commit
3. Ejecutar el commit
4. Restaurar inmediatamente: `cp .env.backup .env`
5. Verificar que el archivo restaurado contiene todos los datos originales

### @Jules — Calidad de Tests

- [ ] Backend: `pytest` pasa en verde (cero fallos, cero errores)
- [ ] Frontend: `flutter test` pasa en verde (cero fallos)
- [ ] Nuevo codigo tiene tests asociados (ver `protocols/tdd.md`)
- [ ] Sin tests marcados como `skip` sin justificacion documentada

### @DevOps — Calidad de Codigo

**Backend:**
```bash
ruff check .              # Cero errores de linting
ruff format --check .     # Formato correcto
```

**Frontend:**
```bash
flutter analyze           # Cero warnings, cero errores
dart format --set-exit-if-changed lib/ test/
```

**Codigo limpio:**
- [ ] Sin `print()` ni `debugPrint()` sin justificacion en codigo productivo
- [ ] Sin imports sin usar (detectado por `ruff` y `flutter analyze`)
- [ ] Sin codigo comentado (dead code): eliminar, no comentar
- [ ] Sin archivos temporales o de debug en staging (`*.tmp`, `*.bak`, `debug_*`)
- [ ] Sin `TODO` ni `FIXME` nuevos sin ticket/issue asociado

---

## FORMATO DE COMMIT OBLIGATORIO

```
<tipo>(<scope>): <descripcion imperativa en tiempo presente>
```

**Tipos validos:**
- `feat` — nueva funcionalidad
- `fix` — correccion de bug
- `refactor` — refactorizacion sin cambio de comportamiento
- `test` — agregar o corregir tests
- `docs` — solo documentacion
- `chore` — dependencias, build, configuracion
- `perf` — mejora de rendimiento
- `style` — formato (sin cambio logico)

**Ejemplos correctos:**
```
feat(auth): add JWT refresh token rotation
fix(map): correct polygon rendering on zoom level 12
test(properties): add edge case for empty search results
chore(deps): bump fastapi from 0.104 to 0.109
```

**Reglas:**
- Descripcion en minusculas, en tiempo presente imperativo ("add", "fix", "update"), sin punto final
- Scope entre parentesis: modulo o area afectada
- Sin "varios cambios", "arreglos", "WIP" en mensajes de commit
- Commits atomicos: un commit = un cambio logico cohesionado

---

## USO DE --no-verify

PROHIBIDO usar `git commit --no-verify` salvo autorizacion explicita del usuario.
Si los hooks de pre-commit fallan, corregir el problema, no saltarselo.
