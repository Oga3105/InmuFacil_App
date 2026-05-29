# Estado de Tareas — InmuFacil

**Ultima actualizacion:** 2026-05-29
**Rama activa:** `develop`
**Estado general:** MVP operacional. Fase de pulido UX/UI y correcciones de produccion.

---

## Completadas (Mayo 2026)

- [x] fix(profile): boton ordenar desbordaba en movil — PR #323
- [x] fix(listing): pisos vendidos aparecian en mapa y listado — PR #324
  - Backend: filtro case-insensitive con func.upper() en properties.py
  - Frontend: status mapeado en PropertyModel.fromJson + safety filter en search_provider
- [x] fix(timeline): acento verde oficial cuando Post-Venta esta FINALIZADO — PR #324
- [x] fix(timeline): links del footer (Ayuda/Legal/Seguridad) dirigidos a pages reales — PR #325
- [x] fix(timeline): dialogo "no disponible" al pulsar Hablar con asesor legal (10 idiomas) — PR #325
- [x] chore(docker): imagen base actualizada a python:3.11-slim (numpy>=2.4.6 requiere Python 3.11+)
- [x] fix(timeline): cursor de mano (hover) en links del footer y en "Hablar con asesor legal"
- [x] fix(timeline): "Seguridad" renombrado a "Terminos" -> ruta /info/terms (10 idiomas)
- [x] fix(navigation): context.push en _FooterLink para que el boton volver regrese al timeline
- [x] fix(navigation): info_screen.dart usa context.pop() con fallback a context.go('/') si pila vacia

---

## Pendiente — Alta Prioridad

- [ ] fix(property-detail): avatar del usuario no se ve en la AppBar de la pantalla de detalle
  - URL: /TFM/property/:id
  - Sintoma: avatar invisible (posiblemente color transparente o fallo en carga de foto)
  - Archivo: frontend/lib/presentation/screens/property/property_details_screen.dart

---

## Pendiente — Media Prioridad

- [ ] Verificar en produccion que pisos vendidos ya no aparecen tras el reinicio del backend (Docker)
- [ ] Revisar que _buildUserAvatar en property_details_screen muestra el fallback correcto cuando no hay foto

---

## Notas de Arquitectura

- El filtro de pisos vendidos opera en dos capas: backend (SQL) + frontend (Riverpod provider).
  La doble capa es intencionada como defensa en profundidad.
- context.go() resetea la pila de GoRouter; usar context.push() cuando se quiera preservar el historial.
- Docker usa python:3.11-slim. requirements.txt esta etiquetado como "Python 3.13" pero el Dockerfile
  se mantiene en 3.11 por compatibilidad probada con EasyOCR y OpenCV.
