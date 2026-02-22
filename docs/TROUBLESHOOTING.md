# Troubleshooting

Problemas comunes y guías de respuesta rápida (DR (Disaster Recovery) en local).

## Docker y VPS
- **Err: `ERR_CONNECTION_REFUSED` / Local web request timeout**
  - Posible origen: El motor de FastAPI ha crasheado silenciosamente por dependencias faltantes en Pydantic y Uvicorn no reinicia.
  - Rescate: Revisa los logs en Docker (`docker logs -f backend_cli`) y verifica que Python esté corriendo el host `0.0.0.0` y no limitándose a la red de loopback.

## Flutter / Dart SDK
- **Err: RenderFlex Overflow (Franja amarilla/negra aserrada) en Maps**
  - Solución frecuente: Modifica contenedores rígidos (`Container` fijos) para utilizar widgets expansivos `Flexible` o `Expanded` si se insertan sin un `SingleChildScrollView`.
- **Caché Sucia**
  - Haz `flutter clean && flutter pub get` si importaste assets sin registrarlos en `pubspec.yaml` primero.

## Base de Datos (Regla No-Alembic)
- Por directiva arquitectural, no se usa Alembic por defecto. Si alteras un modelo `models.py` de tabla y te salta error del tipo *column x does not exist*.
  - Solución: Eres responsable de ejecutar manualmente `ALTER TABLE mytable ADD COLUMN id UUID;` vía consola `psql` para respetar el ADR de Integridad Manual.
