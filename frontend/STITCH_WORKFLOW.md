# Stitch-to-Flutter Workflow Protocol

## 🎨 @UIBuilder - Design Translation Protocol

### Objetivo
Convertir diseños de Google Stitch (HTML + PNG) a widgets Flutter siguiendo Clean Architecture.

---

## 📥 Input: Design Inbox

**Ubicación:** `frontend/design_inbox/`

**Archivos esperados:**
- `[screen_name].html` - Estructura HTML exportada de Stitch
- `[screen_name].png` - Captura visual del diseño

**Nota:** Esta carpeta está en `.gitignore` (archivos temporales, no se suben al repo).

---

## 🔄 Algoritmo de Traducción

### 1. Análisis Visual (PNG)
- Identificar componentes UI (botones, inputs, cards, etc.)
- Determinar jerarquía visual (header, body, footer)
- Detectar espaciado y alineación
- Identificar paleta de colores y tipografía

### 2. Análisis Estructural (HTML)
- Extraer jerarquía de elementos (div, section, etc.)
- Mapear a widgets Flutter:
  - `<div>` con flexbox → `Column` / `Row`
  - `<section>` → `Container` / `Card`
  - `<button>` → `ElevatedButton` / `TextButton`
  - `<input>` → `TextField`
  - `<img>` → `Image.asset` / `Image.network`

### 3. Implementación Clean Architecture

#### A. UI Layer (`lib/presentation/`)

**Estructura:**
```
lib/presentation/
├── screens/
│   └── [feature_name]/
│       ├── [screen_name]_screen.dart
│       └── widgets/
│           ├── [component_1].dart
│           └── [component_2].dart
└── providers/
    └── [feature_name]_provider.dart
```

**Reglas:**
- Usar `ConsumerWidget` (Riverpod) si requiere estado
- Usar `StatelessWidget` para componentes puros
- Aplicar Material Design 3 (theme configurado en `app_theme.dart`)
- Responsive design (usar `MediaQuery` o `LayoutBuilder`)

#### B. State Management (Riverpod)

**Si la pantalla requiere datos:**
```dart
// lib/presentation/providers/auth_provider.dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

**Conectar en el widget:**
```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // ...
  }
}
```

#### C. Routing (GoRouter)

**Registrar en `lib/config/router/app_router.dart`:**
```dart
GoRoute(
  path: '/login',
  name: 'login',
  builder: (context, state) => const LoginScreen(),
),
```

---

## 📋 Checklist de Implementación

Para cada diseño procesado:

- [ ] Analizar PNG y HTML
- [ ] Crear estructura de archivos en `lib/presentation/screens/[feature]/`
- [ ] Implementar widgets siguiendo Material Design 3
- [ ] Crear provider si requiere estado (Riverpod)
- [ ] Registrar ruta en `app_router.dart`
- [ ] Verificar responsive design
- [ ] Probar navegación
- [ ] Eliminar archivos de `design_inbox/` (ya procesados)

---

## 🎯 Ejemplo: Login Screen

**Input:**
- `design_inbox/login.html`
- `design_inbox/login.png`

**Output:**
```
lib/presentation/
├── screens/
│   └── auth/
│       ├── login_screen.dart
│       └── widgets/
│           ├── login_form.dart
│           └── social_login_buttons.dart
└── providers/
    └── auth_provider.dart
```

**Routing:**
```dart
GoRoute(
  path: '/login',
  name: 'login',
  builder: (context, state) => const LoginScreen(),
),
```

---

## 🚫 Restricciones

**@UIBuilder NUNCA debe:**
- Escribir lógica de negocio (eso es del domain layer)
- Hacer llamadas directas a la API (usar providers que llamen a repositories)
- Usar `setState` (usar Riverpod)
- Hardcodear strings (usar `l10n` si hay i18n, o constantes)

**@UIBuilder SÍ debe:**
- Crear widgets limpios y reutilizables
- Aplicar el theme configurado
- Conectar con providers para estado
- Validar inputs en el UI (UX feedback inmediato)

---

## 📊 Workflow Completo

```mermaid
graph LR
    A[Stitch Design] -->|Export| B[design_inbox/]
    B -->|Analyze| C[@UIBuilder]
    C -->|Create| D[Flutter Widgets]
    D -->|Connect| E[Riverpod Providers]
    E -->|Register| F[GoRouter]
    F -->|Test| G[Running App]
    G -->|Delete| H[Clean design_inbox/]
```

---

## ✅ Estado Actual

**Infraestructura:**
- ✅ `frontend/design_inbox/` creada
- ✅ Añadida a `.gitignore`
- ✅ Clean Architecture configurada
- ✅ Riverpod instalado
- ✅ GoRouter configurado
- ✅ Material Design 3 theme listo

**Esperando:**
- 📥 Primer diseño de Stitch en `design_inbox/`

---

**Protocolo activo. @UIBuilder listo para procesar diseños.**
