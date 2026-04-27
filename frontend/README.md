# 📱 InmuFacil — Frontend

Aplicacion Multiplataforma (Web + Android) desarrollada con **Flutter** y gestion de estado reactiva con **Riverpod v3**.

## 📚 Documentacion

Para mantener una fuente unica de la verdad, toda la documentacion reside en el directorio raiz `/docs`.

| Documento | Enlace |
|-----------|--------|
| 🎨 UI y Personalizacion (ThemeData) | [THEME_CUSTOMIZATION.md](../docs/THEME_CUSTOMIZATION.md) |
| 🧪 Testing de Widgets | [TESTING_STRATEGY.md](../docs/TESTING_STRATEGY.md) |
| 📦 Contratos DTO y API | [CONTRACTS.md](../docs/CONTRACTS.md) |
| 🏗️ Arquitectura (Layered/Clean) | [ARCHITECTURE.md](../docs/ARCHITECTURE.md) |

## 🌟 Funcionalidades

- 🔑 Autenticacion: login, registro, Google OAuth, MFA email
- 👤 Perfil: foto, KYC (camara/galeria), verificacion DNI/NIE/Pasaporte
- 🏘️ Publicacion: wizard 5 pasos con descripcion IA (Gemini)
- 🗺️ Mapa interactivo: flutter_map + OpenStreetMap
- 📋 Listado inteligente: SmartExplorerCard, filtros avanzados, comparador
- 💬 Chat P2P: mensajeria con acciones rapidas (visita, oferta)
- 📅 Visitas: calendario, reserva de slots, proximas/pasadas
- 💰 Ofertas: contraofertas, timeline, arras, firma digital
- 🪪 Solvency Passport: asistente de solvencia
- 🌍 i18n: 9 idiomas (ES, EN-US, EN-GB, EN-CA, FR-FR, FR-CA, CA, EU, GL)
- 🔒 GDPR: consentimiento IA, trust dashboard

## 🏗️ Estructura

```
lib/
├── core/                    # Config, formatters, utils
│   └── formatters/          # CurrencyInputFormatter (solo enteros)
├── data/                    # Repositories, data sources, DTOs
├── domain/                  # Entities, use cases
└── presentation/
    ├── screens/             # 50+ pantallas
    │   ├── auth/            # Login, registro, onboarding
    │   ├── property/        # Detalle, publicacion, edicion
    │   ├── chat/            # Lista, detalle
    │   ├── visits/          # Calendario, gestion
    │   ├── offers/          # Negociacion, timeline
    │   └── ...
    ├── widgets/             # Componentes reutilizables
    └── providers/           # Riverpod state management
```

## 🚀 Inicio Rapido

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Configurar variables de entorno
# Editar .env con API_BASE_URL y GOOGLE_WEB_CLIENT_ID

# 3. Ejecutar en desarrollo
flutter run -d chrome --web-port 8001

# 4. Build produccion (Web)
MSYS_NO_PATHCONV=1 flutter build web --release --base-href /TFM/
```

## 🧪 Testing

```bash
flutter test
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## ⚙️ Configuracion

| Variable | Descripcion |
|----------|-------------|
| `API_BASE_URL` | URL del backend (default: `https://inmufacil.com/api/v1`) |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth Client ID |
| `API_TIMEOUT` | Timeout HTTP en ms (default: 30000) |

## 📐 Convenciones

- 🌍 **i18n obligatorio**: usar `.tr()` en todo texto visible — nunca hardcodear strings
- 💰 **Importes monetarios**: solo `int`, usar `CurrencyInputFormatter`
- 📱 **Riverpod v3**: `FutureProvider.autoDispose.family` para datos async con parametro
- 🎨 **Material Design 3**: seguir `Theme.of(context).colorScheme` para dark/light mode
