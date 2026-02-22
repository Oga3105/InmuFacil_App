# ADR 009: Protocolo Permanente de Integridad de Datos (Sin Alembic)

*   **Estado:** Aceptado
*   **Fecha:** 2026-01-29
*   **Contexto:** Sincronización Manual PostgreSQL vs Python Models

## Contexto
No utilizamos herramientas de migración automática (como Alembic) por decisión de diseño para mantener el control total. Sin embargo, esto introduce el riesgo de desincronización entre `backend/models.py` (código) y el esquema real en PostgreSQL (Docker).

## Decisión
Se establece el **Protocolo Permanente de Integridad de Datos**:

1.  **Vigilancia:** El rol @Architect debe monitorear `models.py` en cada iteración.
2.  **Alerta:** Cualquier cambio de campo/tabla dispara una "Alerta de Desincronización".
3.  **Ejecución Manual:** El rol @DevOps debe generar y ejecutar los comandos SQL (`ALTER TABLE`, `CREATE TABLE`) directamente en el contenedor `inmufacil_postgres`.
4.  **Verificación:** Se debe verificar la existencia de las columnas con `psql` tras la migración.

## Consecuencias
*   **Positivas:** Control absoluto del DDL. Evita "magia" de ORMs que pueda corromper datos.
*   **Negativas:** Requiere disciplina férrea. Riesgo humano de olvidar un campo.
*   **Mitigación:** Scripts de verificación (`inspect_db.py`) o consultas directas a `information_schema`.

## Referencia Técnica
Para conectar al contenedor:
```bash
docker exec -it inmufacil_postgres psql -U inmufacil_user -d inmufacil_db
```
