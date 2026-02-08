# ADR 005: Ciclo de Vida y Ejecución de Visitas

*   **Estado:** Aceptado
*   **Fecha:** 2026-01-29
*   **Decisores:** @Watcher, @Architect, @Jules

## Contexto
Hemos implementado la *agrupación* de visitas (Hito 4). Ahora necesitamos gestionar la *ejecución* real de la visita (Hito 5).
Necesitamos un flujo de estados claro que cubra desde la solicitud hasta la conclusión, asegurando que:
1.  El comprador no pueda marcar su propia visita como realizada (Fraude).
2.  Tengamos traza de "No Shows" (Compradores que no aparecen).

## Decisión: Máquina de Estados
Definimos los siguientes estados en `VisitStatus`:

1.  **REQUESTED**: Estado inicial. El comprador elige un slot.
2.  **APPROVED**: El vendedor confirma que la visita sigue en pie.
3.  **REJECTED**: El vendedor la rechaza manual o automáticamente.
4.  **COMPLETED**: La visita ocurrió. (Solo marcable por Vendedor).
5.  **NO_SHOW**: El comprador no apareció. (Solo marcable por Vendedor).
6.  **CANCELLED**: Cancelada previamente por cualquiera de las partes.

### Matriz de Transiciones Permitidas

| Estado Actual | Nuevo Estado Permitido | Rol Autorizado |
| :--- | :--- | :--- |
| REQUESTED | APPROVED | Vendedor |
| REQUESTED | REJECTED | Vendedor |
| REQUESTED | CANCELLED | Comprador/Vendedor |
| APPROVED | CANCELLED | Comprador/Vendedor |
| APPROVED | COMPLETED | **Vendedor** (Critical) |
| APPROVED | NO_SHOW | **Vendedor** |
| COMPLETED | - | - (Final) |

## Defense in Depth (Seguridad)
*   **Role Check:** El endpoint `PATCH /visits/{id}/status` debe validar estrictamente `current_user.id == visit.window.property.owner_id` para transiciones a `COMPLETED` o `NO_SHOW`.
*   **IDOR Prevention:** Un vendedor A no puede cambiar el estado de una visita de la Propiedad del vendedor B.

## Consecuencias
*   Requiere que el vendedor sea activo en la plataforma después de la visita.
*   Prepara el terreno para el sistema de "Reputación de Comprador" (basado en No Shows).
