# API Reference

Este documento describe los contratos de interfaz entre el Backend (FastAPI) y el Frontend (Flutter).

## Endpoints Principales

- `/api/v1/auth`: Autenticación y registro (JWT en Body).
- `/api/v1/properties`: Listado y subida de propiedades, con soporte asíncrono.
- `/api/v1/users`: Gestión de perfiles.
- `/api/v1/visits`: Sistema de visitas en bloque y ciclos de vida.
- `/api/v1/offers`: Ofertas transparentes y negociación híbrida.
- `/api/v1/contracts`: Generador PDF de contratos.

## Convenciones
- **Content-Type**: `application/json` en todas partes.
- **Paginación**: Usualmente mediante `limit` y `offset`.
- **Manejo de Errores**: Objeto JSON con `detail`.
