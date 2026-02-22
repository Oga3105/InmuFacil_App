# ADR 003: Arquitectura de Datos de Propiedades (Modelo Satélite)

*   **Estado:** Aceptado
*   **Decisores:** @Architect, @Jules
*   **Fecha:** 2026-01-28

## Contexto
El proyecto InmuFácil requiere evolucionar de un portal de anuncios simple a una plataforma de "Inteligencia de Activos" para competir en 2026. Esto implica almacenar una gran cantidad de datos técnicos, legales, financieros y ambientales por cada propiedad.

El enfoque tradicional de añadir columnas a una única tabla `properties` (monolítica) presenta problemas:
1.  **Rendimiento:** Las consultas de listado simple (`SELECT * FROM properties`) se volverían pesadas al traer datos irrelevantes para la vista de catálogo (ej. consumos energéticos, datos catastrales).
2.  **Mantenibilidad:** Una tabla con 50+ columnas es difícil de gestionar y migrar.
3.  **Flexibilidad:** Diferentes tipos de propiedades (local vs vivienda) requerirían muchas columnas `NULL`.

## Decisión
Hemos decidido implementar una **Arquitectura de Tablas Satélite (1:1)**.

La entidad `Property` se mantiene ligera (Core) y se delega la información especializada a tablas vinculadas con relación 1:1 estricta:

1.  **`Property` (Core)**: Datos de indexación rápida (Id, Precio, Título, Ubicación, Superficie).
2.  **`PropertyFeatures`**: Detalles físicos (Habitaciones, Año, Domótica).
3.  **`PropertyLegal`**: Datos legales (Certificados, ITE, Referencia Catastral).
4.  **`PropertyFinancial`**: Datos de inversión (IBI, Yield, Rentas estimadas).
5.  **`PropertyEnvironment`**: Datos de entorno (Ruido, Criminalidad, Servicios).

## Consecuencias

### Positivas
*   **Rendimiento en Listados:** El endpoint `/properties` (catálogo) puede optar por no hacer JOINs con los satélites, manteniendo la respuesta ligera.
*   **Organización:** Claridad semántica en el código (`property.financial.gross_yield` vs `property.gross_yield`).
*   **Escalabilidad:** Podemos añadir nuevos satélites (ej. `PropertyHistory`) sin tocar la tabla principal.

### Negativas
*   **Complejidad en Escritura:** Las operaciones `CREATE` y `UPDATE` deben ser transaccionales y manejar múltiples tablas.
*   **Queries Complejas:** Para la vista de detalle (`/properties/{id}`), es necesario usar `joinedload` en SQLAlchemy para evitar el problema N+1.

## Implementación
Se utiliza `SQLAlchemy` con relaciones `uselist=False` (1:1) y `cascade="all, delete-orphan"` para asegurar que al borrar una propiedad se borren sus satélites.
