# ADR 001: Arquitectura Base del Sistema

**Estado:** Aceptado  
**Fecha:** 2026-01-26  
**Autores:** @Architect, @Jules, @Shield

## Contexto

InmuFácil requiere un sistema backend robusto para procesar verificaciones KYC (Know Your Customer) con los siguientes requisitos:

- Procesamiento asíncrono de imágenes de documentos
- Almacenamiento seguro de datos sensibles con cifrado
- Validación estricta de tipos de datos
- Escalabilidad para múltiples usuarios concurrentes
- Cumplimiento con normativas de protección de datos (GDPR)

## Decisión

Adoptamos el siguiente stack tecnológico:

### Backend Framework
- **FastAPI** - Framework web asíncrono moderno
  - Soporte nativo para async/await
  - Validación automática con Pydantic
  - Documentación automática (OpenAPI/Swagger)
  - Alto rendimiento comparable a NodeJS/Go

### Base de Datos
- **PostgreSQL** - Sistema de gestión de base de datos relacional
  - ACID compliance para integridad de datos
  - Soporte para tipos de datos complejos
  - Extensiones para cifrado (pgcrypto)
  - Madurez y estabilidad probada

### ORM
- **SQLAlchemy 2.0** - Object-Relational Mapping
  - Soporte completo para async/await
  - Type hints para seguridad de tipos
  - Migraciones via SQL raw (no Alembic — decision revisada en ADR 009)
  - Flexibilidad para consultas complejas

## Consecuencias

### Positivas
- ✅ Desarrollo rápido con validación automática
- ✅ Código type-safe reduce bugs en producción
- ✅ Escalabilidad horizontal con async
- ✅ Ecosistema maduro con amplia documentación
- ✅ Compatible con GitHub Advanced Security (CodeQL)

### Negativas
- ⚠️ Curva de aprendizaje para async/await
- ⚠️ PostgreSQL requiere infraestructura adicional vs SQLite
- ⚠️ Mayor complejidad inicial vs frameworks síncronos

## Alternativas Consideradas

1. **Django + Django REST Framework**
   - Rechazado: Overhead innecesario, enfoque síncrono
   
2. **Flask + SQLAlchemy**
   - Rechazado: Falta de soporte async nativo, validación manual

3. **Node.js + Express**
   - Rechazado: Preferencia por Python para procesamiento de imágenes

## Actualizaciones

- **2026-03-22:** Corregido — las migraciones usan SQL raw, no Alembic (ver ADR 009 para decision de integridad de DB)
- **2026-03-22:** Stack actualizado — Python 3.13, FastAPI 0.135.1, SQLAlchemy 2.0.48

## Referencias

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy 2.0 Documentation](https://docs.sqlalchemy.org/en/20/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
