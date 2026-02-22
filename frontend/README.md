# InmuFácil - Frontend

Aplicación Multiplataforma (Mobile-First y Web) desarrollada con **Flutter** e inyección de dependencias reactiva mediante **Riverpod**.

## 📚 Documentación

Para mantener una fuente única de la verdad, toda la documentación reside en el directorio raíz `/docs`.

**Enlaces Útiles para el Frontend:**
- [UI y Personalización (ThemeData)](../docs/THEME_CUSTOMIZATION.md)
- [Testing de Widgets](../docs/TESTING_STRATEGY.md)
- [Contratos DTO y API](../docs/CONTRACTS.md)
- [Arquitectura (Layered/Clean)](../docs/ARCHITECTURE.md)

## 🌟 Key Features


Para mantener una fuente única de la verdad, toda la documentación reside en el directorio raíz `/docs`.

**Enlaces Útiles para el Frontend:**
- [UI y Personalización (ThemeData)](../docs/THEME_CUSTOMIZATION.md)
- [Testing de Widgets](../docs/TESTING_STRATEGY.md)
- [Contratos DTO y API](../docs/CONTRACTS.md)
- [Arquitectura (Layered/Clean)](../docs/ARCHITECTURE.md)

## 🚀 Inicio Rápido (Localhost)

```bash
# 1. Obtener dependencias de pubspec
flutter pub get

### 🔒 Security & Limits
- **Rate Limiting:** Debounced requests (500ms) to comply with Nominatim's 1 req/sec policy.
- **Input Sanitization:** Search queries are trimmed, length-limited (200 chars), and validated against a whitelist.
- **User-Agent:** Compliant headers included in all requests.

## 🎨 404 "Not Found" Experience

A custom, secure, and internationally friendly 404 page.

- **Design:** Pixel-Perfect reproduction of isometric 3D art using native Flutter widgets (No heavy assets).
- **Security:** "Notify Me" form includes robust email validation (Regex) and state management to prevent spam.
- **i18n:** Fully translated into 9 languages including error messages and UI elements.
- **Responsiveness:** Adapts layout for mobile (Column) and desktop (Row).

## 🚀 Getting Started

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
2. **Run Development Server:**
   ```bash
   flutter run -d chrome --web-port 8001
   ```

## 🏗️ Project Structure

- `lib/presentation/`: UI components (Screens, Widgets, Providers).
- `lib/domain/`: Business logic and Entities.
- `lib/data/`: Repositories and API implementation.
- `lib/core/`: Utilities, Services, and Configuration.
- `assets/translations/`: i18n JSON files.

## 📝 Configuration

- **Map Provider:** OpenStreetMap (No API key required).
- **Geocoding:** Nominatim (Free, rate-limited).
- **Backend:** Expects API at localhost:8000 (configurable in .env).

