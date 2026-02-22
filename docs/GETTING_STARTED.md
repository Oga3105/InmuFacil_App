# Getting Started - Zero to Hero

Guía rápida para ejecutar el entorno de desarrollo local (Localhost).

## Requisitos Previos
- Flutter SDK (Última versión estable).
- Python 3.10+ o superior.
- Docker Desktop (Para Base de datos local transaccional).

## Entorno Local (Multimplataforma: Windows/Mac/Linux)

### 1. Backend (FastAPI)
1. Navega al directorio `/backend/`.
2. Crea un entorno virtual: `python -m venv venv`.
3. Activa el entorno virtual:
   - Windows: `venv\Scripts\activate`
   - Unix: `source venv/bin/activate`
4. Instala dependencias: `pip install -r requirements.txt`.
5. Levanta la Base de Datos en Docker local o configura `.env` con un SQLite temporal para pruebas rápidas.
6. Inicia el servidor: `uvicorn main:app --reload` (Correrá en el puerto 8000).

### 2. Frontend (Flutter)
1. Navega al directorio `/frontend/`.
2. Descarga los paquetes: `flutter pub get`.
3. Lanza el proyecto:
   - Web: `flutter run -d chrome --web-port 8001`
   - Móvil: Ejecuta el emulador correspondiente desde tu IDE y usa `flutter run`.
