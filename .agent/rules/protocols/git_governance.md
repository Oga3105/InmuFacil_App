# ⚖️ PROTOCOLO DE GOBERNANZA GIT

**Regla de Oro:** Los agentes deben detenerse y DEBATIR entre @DevOps y @Shield antes de alterar el repositorio.

## 🌳 Gestión de Ramas (Git Flow)
**Trigger:** Inicio de cualquier nueva tarea o feature.
**Responsable:** @DevOps

### Reglas de Actuación
1.  **Inicio:** NUNCA trabajar en `develop` directo para cambios mayores.
    *   Usar: `git checkout -b feature/[nombre-tarea]`
2.  **Desarrollo:** Commits atómicos y frecuentes.
    *   Formato: `feat: implement logic for X`
3.  **Validación Local:**
    *   Ejecutar tests: `pytest` (Si ❌ -> Corregir).
4.  **Publicación OBLIGATORIA (Remote Sync):**
    *   **CRÍTICO:** ANTES de cualquier fusión a `develop`, la feature DEBE existir en remoto.
    *   Ejecutar: `git push origin feature/[nombre-tarea]`
    *   Verificar que la rama aparece en el repositorio remoto.
5.  **Fusión (Merge Policy):**
    *   **Condición:** Paso 4 completado + Tests en Verde.
    *   `git checkout develop`
    *   `git merge --no-ff feature/[nombre-tarea]` (Preservar historia)
    *   `git push origin develop`

## 🚦 Matriz de Decisión (Debate Requerido)

### 1. ¿Feature o Fix?
- **Nueva funcionalidad** → `feature/[nombre-descriptivo]`
- **Arreglo de bug** → `fix/[nombre-bug]`
- **Refactor sin cambios lógicos** → `chore/[nombre-tarea]`
- **Documentación** → `docs/[nombre-doc]`

### 2. ¿PR o Directo?
- **Si afecta a `develop` o `main`** → **PR OBLIGATORIA** (`gh pr create`)
- **Si es sub-tarea experimental** → Commit directo permitido en rama `feature`
- **Hotfix crítico** → PR express con aprobación rápida

### 3. ¿Cuándo fusionar?
- ✅ **Condición 1:** Tests pasando (verde)
- ✅ **Condición 2:** @Shield valida seguridad
- ✅ **Condición 3:** Rama pusheada a remoto
- ✅ **Método:** Usar siempre `git merge --no-ff` para preservar historia

## 📜 Política de Ramas Remotas (TFM)
- ✅ **PRESERVAR** todas las ramas remotas como registro histórico
- ✅ **ELIMINAR** solo ramas locales obsoletas
- ✅ Mantener evidencia de desarrollo iterativo para evaluación académica

## Criterios de Aprobación de PR
**@DevOps verifica:**
- [ ] Rama existe en remoto
- [ ] Commits atómicos y descriptivos
- [ ] Sin conflictos con develop

**@Shield verifica:**
- [ ] Sin secretos hardcodeados
- [ ] Sin vulnerabilidades evidentes
- [ ] Manejo correcto de PII

**@Jules verifica:**
- [ ] Tests pasando
- [ ] Cobertura adecuada
- [ ] Sin regresiones

**@Architect verifica:**
- [ ] Arquitectura consistente
- [ ] Sin deuda técnica innecesaria
- [ ] Documentación actualizada
