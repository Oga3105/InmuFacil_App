# Estado de Tareas — InmuFacil

**Ultima actualizacion:** 2026-06-04
**Rama activa:** `develop`
**Estado general:** MVP operacional. Fase de pulido UX/UI, correcciones de produccion y preparacion de entrega TFM.

---

## Completadas (Junio 2026)

- [x] fix(offers): simbolo euro detras de la cantidad, titulo "Aceptar oferta" bicolor, boton Cancelar visible oscuro, footer links con navegacion real — PR #334
- [x] fix(offers): context.push en footer links (back button preservado) — PR #335
- [x] fix(property): metricas visitas/favoritos visibles a no-propietarios, fix URL doble /api/v1, "Ver proceso de cierre" visible en oscuro — PR #336
- [x] fix(offers): ValueKey en _OfferCard + ref.invalidate tras aceptar para recargar UI — PR #337
- [x] fix(offers): texto card solvencia visible en modo oscuro (verde adaptativo) — PR #338, #341
- [x] fix(offers): super.key en _OfferCard — fix error compilacion dart2js — PR #339
- [x] fix(timeline): "Financiacion" no se trunca en movil — PR #340
- [x] fix(timeline): valores solvencia alineados a izquierda — PR #342
- [x] fix(timeline): fondo card solvencia modo oscuro azul marino en lugar de verde oscuro — PR #343
- [x] feat(arras): modo oscuro completo en ArrasEquityAnalysisScreen — PR #344
- [x] fix(auth): 500 en /reset-password por bug naive/aware datetime (utcnow->now(timezone.utc)) — PR #345
- [x] feat(ui): cursor pointer en logo AppBar en 11 pantallas — PR #346

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

## Pendiente — Alta Prioridad (TFM)

- [x] **Slides URL**: Desplegadas en https://inmufacil.com/TFM/slides — URL publica disponible para el formulario TFM
- [ ] Confirmar visibilidad publica del repositorio GitHub (o conceder acceso a mouredev@gmail.com)

## Pendiente — UX/UI

- [ ] fix(property-detail): avatar del usuario no se ve en la AppBar de la pantalla de detalle
  - URL: /TFM/property/:id
  - Archivo: frontend/lib/presentation/screens/property/property_details_screen.dart

---

## Pendiente — Media Prioridad

- [ ] Verificar en produccion que pisos vendidos ya no aparecen tras el reinicio del backend (Docker)
- [ ] Limpiar archivos basura del root del repo (*.db, diff.txt, curl_res.json, *.dart sueltos)

---

## Notas de Arquitectura

- El filtro de pisos vendidos opera en dos capas: backend (SQL) + frontend (Riverpod provider).
  La doble capa es intencionada como defensa en profundidad.
- context.go() resetea la pila de GoRouter; usar context.push() cuando se quiera preservar el historial.
- Docker usa python:3.11-slim. requirements.txt esta etiquetado como "Python 3.13" pero el Dockerfile
  se mantiene en 3.11 por compatibilidad probada con EasyOCR y OpenCV.
