# Flutter Frontend - InmuFácil

## Arquitectura

Este proyecto sigue **Clean Architecture** estricta con 3 capas:

### 📦 Domain Layer (`lib/domain/`)
- **Entidades:** Objetos de negocio puros (sin dependencias de Flutter)
- **Repositorios:** Contratos abstractos
- **Use Cases:** Lógica de negocio

### 📊 Data Layer (`lib/data/`)
- **Models:** DTOs con serialización JSON
- **Repositories:** Implementaciones de contratos
- **Data Sources:** API clients, local storage

### 🎨 Presentation Layer (`lib/presentation/`)
- **Screens:** Pantallas completas
- **Widgets:** Componentes reutilizables
- **Providers:** Estado con Riverpod

## Configuración

### Requisitos
- Flutter SDK >=3.0.0
- Dart >=3.0.0

### Instalación

```bash
# Instalar dependencias
flutter pub get

# Generar código (JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Ejecutar en modo desarrollo
flutter run
```

### Variables de Entorno

El proyecto usa `.env.development` y `.env.production`:

```env
API_BASE_URL=http://localhost:8000
API_TIMEOUT=30000
ENABLE_LOGGING=true
```

## Estructura de Directorios

```
lib/
├── core/              # Utilidades compartidas
├── domain/            # Lógica de negocio
├── data/              # Implementaciones de datos
└── presentation/      # UI (workspace de @UIBuilder)
```

## Guía para @UIBuilder

### Zona de Trabajo
Implementar screens y widgets en `lib/presentation/`

### Restricciones
- ❌ NO escribir lógica de negocio en presentation
- ❌ NO hacer llamadas HTTP directas
- ✅ Usar Riverpod providers para estado
- ✅ Consumir UseCases del domain layer
- ✅ Validar con @FrontendProxy

### Flujo de Trabajo
1. Recibir diseño de Stich
2. Crear widgets en `presentation/screens/`
3. Implementar providers en `presentation/providers/`
4. Conectar con UseCases existentes
5. Validar con @FrontendProxy

## Testing

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/presentation/

# Integration tests
flutter test integration_test/
```

## Seguridad (@Shield)

- JWT tokens almacenados en `flutter_secure_storage`
- Interceptores automáticos para autenticación
- Manejo de 401 (token expirado)
- Sin secretos hardcodeados

## Estado del Proyecto

✅ Estructura de directorios creada
✅ Configuración de dependencias
✅ API client con JWT interceptors
✅ Routing básico configurado
✅ Tema Material Design 3
⏳ Pendiente: Implementación de screens por @UIBuilder
