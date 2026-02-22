# Architecture Overview

Visión general de InmuFacil, combinando robustez en el backend con una experiencia multiplataforma en frontend.

## Frontend (Flutter)
- **Framework**: Flutter (Mobile First, Modular).
- **Gestión de Estado**: Riverpod para inyección de dependencias y reactividad.
- **Estructura**: Clean Architecture (Capa Presentation, Domain, Infrastructure, Configuration).

## Backend (FastAPI)
- **Framework**: FastAPI (Asíncrono, Alto rendimiento).
- **Validación**: Pydantic.
- **Base de Datos**: PostgreSQL + SQLAlchemy (Arquitectura de Tablas Satélite para Propiedades).
- **Procesamiento Documentos**: EasyOCR para anonimización automática.
- **Infraestructura**: Dockerizado de extremo a extremo.
