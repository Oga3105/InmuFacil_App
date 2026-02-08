# 📚 Protocolo: "Documentación Primero" (Docs First)

## Trigger
Antes de cualquier `git push` o Pull Request.

## Regla de Oro
**PROHIBIDO subir código sin actualizar su documentación asociada.**

## Flujo de Trabajo
1.  **Agente Implementador (@Jules/@Architect):** Termina el código y los tests.
2.  **Agente Documentador (@Watcher):**
    *   Actualiza `scratchpad.md` (Estado de Misión).
    *   Actualiza `task.md` (Checklists de hitos).
    *   Actualiza `ADRs` si hubo cambios de arquitectura.
    *   Actualiza `vision_proyecto.md` si cambió el alcance.
3.  **Agente DevOps (@DevOps):**
    *   Verifica que los docs han sido modificados.
    *   Ejecuta: `git add`, `git commit`, `git push`.
