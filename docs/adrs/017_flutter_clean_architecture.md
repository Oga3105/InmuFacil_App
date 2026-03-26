# ADR 017: Flutter — Arquitectura, Estado y Navegacion

**Estado:** Aceptado
**Fecha:** 2026-03-22
**Autores:** @Architect, @UIBuilder, @FrontendProxy

---

## Contexto

Con el frontend Flutter evolucionando de pantallas aisladas a una aplicacion completa con 50+ pantallas, multiples dominios de negocio y estado compartido, se necesitaba establecer patrones claros y consistentes para:
- Gestion de estado global y local
- Navegacion entre pantallas
- Integracion con el backend (HTTP)
- Soporte multi-plataforma (Web + Android)
- Internacionalizacion (9 idiomas)

---

## Decisiones

### 1. Gestion de Estado: Riverpod v3

Se adopta **flutter_riverpod 3.2.1** como unico sistema de gestion de estado.

**Patrones canonicos por caso de uso:**

| Caso de uso | Patron Riverpod |
|---|---|
| Autenticacion (estado global mutable) | `NotifierProvider<AuthNotifier, AuthState>` |
| Datos async con parametro | `FutureProvider.autoDispose.family<T, Arg>` |
| Notificadores async complejos | `AsyncNotifier<T>` + `AsyncNotifierProvider` |
| Mutaciones en pantalla | Llamada Dio directa + `ref.invalidate(provider)` para refrescar |

**Eliminado definitivamente:** `StateNotifier` y `StateNotifierProvider` (API legacy de Riverpod v1/v2). Cualquier nuevo provider debe usar los patrones de v3.

### 2. Navegacion: GoRouter v17

Se adopta **go_router 17.1.0** con configuracion declarativa centralizada en `app_router.dart`.

Reglas:
- Todas las rutas declaradas en un unico archivo
- Rutas con parametros usan `:id` en la URL
- Navegacion programatica: `context.push()`, `context.go()`, `context.pop()`
- Las rutas de onboarding Google (`/onboarding/consent`, `/onboarding/user-type`) son rutas completas (no dialogs) para tener historial de navegacion limpio

### 3. Arquitectura de Capas (Clean Architecture)

```
presentation/  ← Widgets, Screens, Providers (Riverpod)
domain/        ← Entities (User, Property, Offer...) — clases puras, sin framework
data/          ← Repositories (implementacion Dio), Models (JSON parsing)
config/        ← Router, Theme, Env
core/          ← Formatters, Widgets compartidos globales
```

Regla: Las entidades de `domain/` no dependen de Flutter ni de ninguna libreria externa.

### 4. HTTP Client: Dio con token centralizado

El token JWT se gestiona en `AuthNotifier` y se inyecta en las cabeceras de `Dio` globalmente:
```dart
_dio.options.headers['Authorization'] = 'Bearer $token';
```

Al hacer logout, se limpia el header y se invalidan todos los providers dependientes de datos del usuario.

### 5. Campos monetarios — Enteros siempre

Todos los campos de precio, oferta y contraoferta son `int` en Dart y `int` en Python/PostgreSQL. Usar `CurrencyInputFormatter` para formatear con separador de miles en los TextFields.

**Excepcion:** `surface_area` (m²) admite decimales.

### 6. Internacionalizacion: easy_localization

**Politica estricta (NON-NEGOTIABLE):**
- Prohibido hardcodear strings en widgets
- Obligatorio usar `.tr()` para todo texto visible al usuario
- 9 idiomas: es-ES (principal), en-US, fr-FR, de-DE, it-IT, pt-PT, zh-CN, ar-SA, ro-RO
- Archivos en `frontend/assets/translations/<locale>.json`

### 7. Widgets compartidos clave

- `AppBarBackButton`: el parametro `onPressed` es REQUIRED, nunca usar sin el
- `GoogleSignInButton`: widget reutilizable con CustomPainter para el logo de Google
- `CurrencyInputFormatter`: formateador para campos monetarios

---

## Consecuencias

### Positivas
- Estructura predecible para todos los nuevos desarrollos
- Riverpod v3 con `ref.invalidate()` garantiza datos frescos tras mutaciones sin estado inconsistente
- GoRouter permite deep linking y URL legibles en Flutter Web
- Clean Architecture desacopla la logica de negocio de Flutter, facilitando tests unitarios

### Negativas
- Curva de aprendizaje de Riverpod v3 (especialmente `AsyncNotifier` y `family`)
- La centralizacion de rutas en `app_router.dart` puede crecer mucho — mitigar con comentarios de seccion
- Tests de widget con Riverpod requieren `ProviderScope` wrapping en cada test

---

## Alternativas Consideradas

1. **BLoC / Cubit**
   - Rechazado: Mayor boilerplate que Riverpod v3, menos ergonomico para datos async

2. **Provider (simple)**
   - Rechazado: No escala bien con multiples dominios de estado

3. **GetX**
   - Rechazado: Mezcla navegacion, estado e inyeccion de dependencias de forma opaca
