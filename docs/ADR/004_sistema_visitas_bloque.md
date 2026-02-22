# ADR 004: Sistema de Visitas en Bloque (Batch Visits)

*   **Estado:** Aceptado
*   **Fecha:** 2026-01-29
*   **Decisores:** @Architect, @Jules, @Watcher

## Contexto
El modelo tradicional de citas 1 a 1 es ineficiente. InmuFácil propone "Visitas en Bloque".
Necesitamos una arquitectura que permita al vendedor definir "Ventanas de Disponibilidad" y al sistema gestionar la fragmentación de estas ventanas en "Slots" para los compradores.

## Decisión
Implementar un modelo de datos `VisitWindow` (1) -> `VisitAppointment` (N).

### 1. Modelo de Datos
*   **VisitWindow**: Define el bloque completo (ej: 10:00 - 14:00).
    *   `slot_duration_minutes`: Configurable (default 20 min).
*   **VisitAppointment**: Reserva puntual dentro de la ventana.

### 2. Algoritmo de Slots (Server-Side)
En lugar de pre-generar miles de filas en la DB para cada slot vacío, calculamos los slots dinámicamente en tiempo de lectura (`GET /slots`).
*   **Input**: Ventana (Start, End, Duration), Citas Existentes.
*   **Output**: Lista de Slots calculados con flag `is_available`.

### 3. Reglas de Negocio
*   **Overlap Prevention**: Un vendedor no puede crear ventanas solapadas para la misma propiedad.
*   **Validación de Comprador**: Solo usuarios activos pueden reservar.
*   **Opacidad**: El comprador ve slots disponibles, no quién más va.

## Consecuencias
*   **Positivo**: Ahorro masivo de espacio en DB (no guardamos slots vacíos).
*   **Positivo**: Flexibilidad para cambiar la duración de slots en el futuro (solo afecta a visualización).
*   **Negativo**: Requiere lógica de aplicación robusta para detectar colisiones en tiempo real.
