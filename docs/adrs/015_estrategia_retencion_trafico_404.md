# ADR-015: Estrategia de Retención de Tráfico en Errores 404 (Lead Magnet)

## Estado
Aceptado

## Contexto
El análisis de tráfico web indica que los errores de navegación (404) resultan actualmente en una pérdida total del usuario (tasa de rebote del 100%). En la fase de lanzamiento de InmuFácil, maximizar la captación de *Early Adopters* es prioritario. La arquitectura actual trata el error 404 como un estado terminal, desperdiciando oportunidades de conversión.

## Decisión
Se decide transformar la página 404 en un punto de entrada activo ("Lead Magnet") mediante la implementación de un sistema de captura de emails ligero y seguro.

### Detalles Técnicos
1.  **Backend:** Creación de modelo `Lead` y endpoint `POST /api/v1/leads` en FastAPI.
2.  **Aislamiento de Datos:** La tabla `leads` estará físicamente separada de `users` para evitar contaminación de datos de identidad con datos de marketing.
3.  **Seguridad:** Implementación de **Idempotencia Silenciosa**. Si un email ya existe, la API responde `200 OK` para evitar ataques de enumeración de usuarios.
4.  **Frontend:** Integración de formulario reactivo en `NotFoundScreen` con validación en tiempo real.

## Consecuencias
* **Positivas:** Conversión de errores técnicos en activos de negocio; Arquitectura resiliente a spam mediante Rate Limiting; Cumplimiento de principios de opacidad de datos.
* **Negativas:** Incremento en la carga de mantenimiento de base de datos (limpieza de leads antiguos).
