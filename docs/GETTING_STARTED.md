# Getting Started — InmuFacil

**Version:** 2.0
**Fecha:** Marzo 2026

---

## Requisitos Previos

- **Flutter SDK** (ultima version estable — comprobar con `flutter --version`)
- **Python 3.13+**
- **Docker Desktop** con Docker Compose v2
- **Git**

---

## 1. Clonar el repositorio

```bash
git clone https://github.com/Oga3105/InmuFacil_App.git
cd InmuFacil_App
git checkout develop
```

---

## 2. Configurar variables de entorno

### Backend (.env en la raiz del proyecto)

```bash
cp .env.example .env
```

Editar `.env` con los valores reales:

```env
DATABASE_URL=postgresql+psycopg2://inmufacil_user:passwordSeguro123@db:5432/inmufacil_db
SECRET_KEY=<valor aleatorio>
SECRET_KEY_JWT=<base64 de 32 bytes — usar: openssl rand -base64 32>
INMUFACIL_MASTER_KEY=<clave Fernet — usar: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())">
GEMINI_API_KEY=<API key de Google AI Studio>
GOOGLE_WEB_CLIENT_ID=<Web Client ID de Google Cloud Console>
ENVIRONMENT=development
DEBUG=true
```

### Frontend (frontend/.env)

```bash
cp frontend/.env.example frontend/.env  # si existe, o crear manualmente
```

```env
API_BASE_URL=http://localhost:8000/api/v1
GOOGLE_WEB_CLIENT_ID=<mismo valor que en .env raiz>
ENABLE_LOGGING=true
```

---

## 3. Levantar el backend con Docker

```bash
# Desde la raiz del proyecto
docker compose up -d

# Verificar que los contenedores estan corriendo
docker compose ps

# Ver logs del backend
docker compose logs -f backend
```

El backend estara disponible en `http://localhost:8000`
Swagger UI: `http://localhost:8000/docs`

---

## 4. Ejecutar migraciones de base de datos

La primera vez (o cuando haya nuevas migraciones):

```bash
# Listar migraciones disponibles
ls backend/migrations/

# Ejecutar una migracion (ejemplo)
docker exec -i <nombre_contenedor_db> psql -U inmufacil_user -d inmufacil_db \
  < backend/migrations/add_google_oauth_to_users.sql
```

> El nombre del contenedor de BD suele ser `inmufacil_project-db-1`. Verificar con `docker compose ps`.

---

## 5. Levantar el frontend Flutter

```bash
cd frontend

# Instalar dependencias
flutter pub get

# Generar codigo (si hay cambios en anotaciones)
dart run build_runner build --delete-conflicting-outputs

# Ejecutar en web (desarrollo)
flutter run -d chrome --web-port 8001

# Ejecutar en Android (con emulador o dispositivo conectado)
flutter run
```

---

## 6. Google Sign-In — Configuracion

Para que el boton de Google funcione:

1. Ir a [Google Cloud Console](https://console.cloud.google.com)
2. Crear proyecto → APIs y Servicios → Credenciales
3. Crear **OAuth 2.0 Client ID** de tipo **Web application**
4. Agregar en "Origenes autorizados": `http://localhost:8001`
5. Copiar el **Client ID** y pegarlo en `.env` y `frontend/.env` como `GOOGLE_WEB_CLIENT_ID`
6. Reiniciar la aplicacion Flutter

> Si `GOOGLE_WEB_CLIENT_ID` esta vacio, el boton de Google mostrara un mensaje de error claro en lugar de un crash.

---

## 7. Ejecutar tests

### Backend

```bash
# Instalar dependencias (primera vez)
pip install -r requirements.txt

# Todos los tests
pytest

# Con cobertura
pytest --cov=backend/src --cov-report=term-missing

# Tests especificos
pytest backend/tests/test_auth.py -v
```

### Frontend

```bash
cd frontend
flutter test
flutter test --coverage
```

---

## Estructura rapida del proyecto

```
InmuFacil_Project/
├── backend/           # FastAPI — API REST
│   ├── src/           # Codigo fuente (routes, models, services...)
│   ├── tests/         # Tests pytest
│   └── migrations/    # Migraciones SQL
├── frontend/          # Flutter — App movil y web
│   ├── lib/           # Codigo Dart (Clean Architecture)
│   ├── assets/        # Traducciones, iconos, imagenes
│   └── test/          # Tests flutter
├── docs/              # Documentacion tecnica + ADRs
├── .agents/           # Protocolos de agentes internos
├── docker-compose.yml # Stack completo local
├── .env               # Variables de entorno (NO commitear)
└── requirements.txt   # Dependencias Python
```

---

## Comandos utiles

```bash
# Parar todos los contenedores
docker compose down

# Parar y limpiar volumenes (reinicia la BD)
docker compose down -v

# Reconstruir la imagen del backend
docker compose up -d --build backend

# Ver logs en tiempo real
docker compose logs -f

# Acceso directo a PostgreSQL
docker exec -it <contenedor_db> psql -U inmufacil_user -d inmufacil_db

# Generar build Flutter para produccion
cd frontend && flutter build web --release --base-href /TFM/
```
