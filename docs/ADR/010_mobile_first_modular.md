# ADR 010: Estrategia Multi-Plataforma y Refactorización Modular

*   **Estado:** Aceptado
*   **Fecha:** 2026-01-30
*   **Contexto:** Crecimiento del proyecto y necesidad de app nativa (Flutter).

## Decisión
1.  **Estrategia Multi-Plataforma (Flutter):** La API soportará un **frontend unificado** tanto para **Web Responsiva** como **Apps Nativas (iOS/Android)** usando Flutter. Requiere una API agnóstica a la plataforma.
    *   Autenticación vía **JWT en Body** (Client-side storage en SecureStorage).
    *   No se usarán Cookies HttpOnly / Session-based auth.
2.  **Agente @FrontendProxy:** Se crea este rol para validar cada endpoint desde la perspectiva de un desarrollador Flutter (Dart Widgets).
3.  **Refactorización Modular:** Se abandona la estructura plana (`routers/`, `models.py`) en favor de una arquitectura en capas (`controllers`, `services`, `models`, `routes`) dentro de `src/`.

## Consecuencias
*   **Positivas:** Mayor mantenibilidad, fácil navegación, preparado para equipos grandes.
*   **Negativas:** Requiere un refactor masivo inmediato (Riesgo de romper imports).
*   **Mitigación:** Tests exhaustivos antes y después del movimiento.
