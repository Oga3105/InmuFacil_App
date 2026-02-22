# InmuFácil - Backend

Este servidor está construido con **FastAPI** y **PostgreSQL** para proveer APIs de alto rendimiento al ecosistema InmuFácil.

## 📚 Documentación

Para mantener una fuente única de la verdad, toda la documentación reside en el directorio raíz `/docs`.

**Enlaces Útiles para el Backend:**
- [Arquitectura (Satélites DB, FastAPI)](../docs/ARCHITECTURE.md)
- [Referencia de API](../docs/API_REFERENCE.md)
- [Contratos de Datos](../docs/CONTRACTS.md)
- [Máquinas de Estado (Core Logic)](../docs/STATE_MACHINE.md)
- [Guía de Despliegue con Docker](../docs/DEPLOYMENT_GUIDE.md)

## 🚀 Inicio Rápido (Localhost)

```bash
# 1. Crear y activar entorno virtual
python -m venv venv
# Activar: venv\Scripts\activate (Windows) o source venv/bin/activate (Unix)

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Levantar servicio (requiere Docker DB o un SQLite en .env local)
uvicorn main:app --reload
```
