# 🎯 Protocolo: "Agentes, reuníos"

## Trigger
El usuario pronuncia la frase clave "Agentes, reuníos".

## Variantes de Ejecución
1.  **Con Orden Específica:** (Ej. "Agentes, reuníos y arreglad el login").
    *   **Acción:** Ejecutar la orden priorizando la delegación correcta entre los agentes.
2.  **Sin Orden (Invocación Sola):**
    *   **Acción:** Ejecutar "Protocolo de Salud General" y revisión de congruencia.

## Protocolo de Salud General (Checklist Automático)
*   **Congruencia Documental:** Verificar que `README.md`, `vision_proyecto.md`, `task.md` y `scratchpad.md` reflejan fielmente el estado actual del código.
*   **Limpieza:** Eliminar inmediatamente archivos basura o temporales.
*   **Git Sync:** Asegurar que TODA rama local (`feature/` o `fix/`) se suba al remoto ANTES de fusionar.
*   **Merge Policy:** Fusionar a `develop` **SI Y SOLO SI**:
    1.  La rama feature existe en remoto.
    2.  Los tests están en VERDE (Pasando).
*   **Revisión de Tareas:** Identificar pendientes no asignados.

## Checklist del Consejo
*   **@Architect:** Revisar coherencia de ADRs, estructura de carpetas y deuda técnica.
*   **@Jules:** Verificar tareas pendientes en `task.md`, estado de tests y cobertura.
*   **@Shield:** Auditar logs recientes, verificar alertas de seguridad y secretos.
*   **@Watcher:** Revisar estado de métricas, logs de auditoría y rendimiento.
*   **@FrontendProxy:** Validar paridad API vs UI Mockups, necesidades de endpoints.
*   **@DevOps:** Verificar estado de ramas git, commits pendientes, y pipelines.
