# InmuFácil Frontend

Platform for P2P property trading without intermediaries. Built with Flutter.

## 🌟 Key Features

- **Property Search:** Advanced filtering by price, type, and location.
- **Interactive Map:** OpenStreetMap integration with clustering and dynamic reloading.
- **Geocoding (New):** Intelligent city search with "Local First, Global Fallback" algorithm.
- **Internationalization:** Full support for 9 languages (ES, EN, CA, EU, GL, FR).
- **Responsive Design:** Optimized for both Desktop and Mobile web views.

## 🗺️ Geocoding Service

The application uses **OpenStreetMap Nominatim API** for city search functionality.

### 🧠 Algorithm: "Local First, Global Fallback"
1. **Primary Attempt:** Searches within Spain (`countrycodes=es`).
   - Ensures inputs like "Córdoba" resolve to Córdoba, Spain.
2. **Fallback:** If no local result found, searches globally.
   - Enables finding "Paris", "New York", or "Córdoba, Argentina".

### 🔒 Security & Limits
- **Rate Limiting:** Debounced requests (500ms) to comply with Nominatim's 1 req/sec policy.
- **Input Sanitization:** Search queries are trimmed, length-limited (200 chars), and validated against a whitelist.
- **User-Agent:** Compliant headers included in all requests.

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
- **Backend:** Expects API at `localhost:8000` (configurable in `.env`).
