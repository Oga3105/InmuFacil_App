# Deployment Guide — InmuFacil

**Version:** 2.0
**Fecha:** Marzo 2026

---

## Arquitectura de Despliegue

```
[Usuario]
    |
    | HTTPS
    |
[Cloudflare CDN/Proxy]  ← SSL terminado aqui
    |
    | HTTP (tunel seguro)
    |
[VPS Debian 12]
    ├── Nginx (puerto 80/443)
    │   ├── /TFM → Flutter Web build (archivos estaticos)
    │   └── /api → proxy_pass a Docker backend (8000)
    └── Docker Compose
        ├── backend (FastAPI, puerto 8000)
        └── db (PostgreSQL 15, puerto 5432 interno)
```

---

## Dominios y DNS (Cloudflare)

**Registrador:** IONOS (nameservers cambiados a Cloudflare)
**Nameservers:** `hope.ns.cloudflare.com` / `rodney.ns.cloudflare.com`
**Zone ID:** `117f5abc1238908b73a3cea2c8b2bd6a`

### Registros DNS activos

| Tipo | Nombre | Destino | Proxy |
|---|---|---|---|
| A | @ (inmufacil.com) | IP_VPS | Si (naranja) |
| A | www | IP_VPS | Si (naranja) |
| A | api | IP_VPS | Si (naranja) |

### Dominios adicionales (redireccion a inmufacil.com)

Los siguientes dominios deben configurarse con reglas de redireccion 301 en Cloudflare hacia `https://inmufacil.com`:
- `inmufacil.es`
- `inmufacil.store`
- `inmufacil.info`
- `inmueblefacilentreparticulares.com`
- `inmueblefacilentreparticulares.es`

### SSL/TLS

En Cloudflare Dashboard → SSL/TLS → Modo: **Full (strict)**
(El VPS debe tener un certificado valido — usar Let's Encrypt o Cloudflare Origin Certificate)

### Indexacion

El sitio NO debe ser indexado publicamente durante el TFM.
En Cloudflare o Nginx, servir `X-Robots-Tag: noindex, nofollow` en todas las respuestas.

---

## Entorno Local (Desarrollo)

### Requisitos
- Docker Desktop (con Docker Compose v2)
- Flutter SDK (ultima version estable)
- Python 3.13+ (para desarrollo backend sin Docker)

### 1. Configurar variables de entorno

```bash
# Copia el template
cp .env.example .env

# Edita .env con tus valores reales:
# DATABASE_URL, SECRET_KEY_JWT, INMUFACIL_MASTER_KEY, GEMINI_API_KEY
# GOOGLE_WEB_CLIENT_ID (obtenlo en console.cloud.google.com)
```

```bash
# Frontend — copia el template
cp frontend/.env.example frontend/.env

# Edita frontend/.env:
# API_BASE_URL=http://localhost:8000/api/v1
# GOOGLE_WEB_CLIENT_ID=<mismo que en .env raiz>
```

### 2. Levantar backend + base de datos

```bash
docker compose up -d
```

Esto levanta:
- PostgreSQL en `localhost:5432`
- FastAPI en `http://localhost:8000`
- Swagger UI disponible en `http://localhost:8000/docs`

### 3. Ejecutar migraciones (primera vez)

```bash
# Ver que contenedor tiene PostgreSQL
docker ps

# Ejecutar migracion
docker exec -i <nombre_contenedor_db> psql -U inmufacil_user -d inmufacil_db < backend/migrations/<archivo>.sql
```

### 4. Levantar frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 8001
```

---

## Despliegue en VPS (Produccion)

### Estado actual (Marzo 2026)

- VPS nuevo adquirido, configuracion en progreso
- Docker instalacion pendiente de completar
- Nginx instalado (gestionado por Plesk si aplica)
- Cloudflare DNS ya apunta al VPS

### Pasos de instalacion Docker (Debian 12)

```bash
# Instalar dependencias
apt-get update
apt-get install -y ca-certificates curl gnupg

# Agregar repositorio oficial Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Escribir sources.list (una sola linea, sin saltos)
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list

# Instalar Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
systemctl start docker
```

### Despliegue de la aplicacion

```bash
# En el VPS, clonar el repositorio
git clone https://github.com/Oga3105/InmuFacil_App.git /opt/inmufacil
cd /opt/inmufacil

# Crear .env con variables de produccion
nano .env  # (completar todos los valores reales)

# Levantar servicios
docker compose up -d --build

# Verificar estado
docker compose ps
docker compose logs -f backend
```

### Configuracion Nginx para Flutter Web

```nginx
server {
    listen 80;
    server_name inmufacil.com www.inmufacil.com;

    # Redirigir todo a HTTPS (Cloudflare maneja el SSL externo)
    # Si usas Cloudflare Flexible SSL, escuchar en 80 es suficiente

    # Flutter Web en /TFM
    location /TFM {
        alias /opt/inmufacil/frontend/build/web;
        try_files $uri $uri/ /TFM/index.html;
    }

    # Proxy al backend FastAPI
    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Todo lo demas → 404
    location / {
        return 404;
    }
}
```

### Build Flutter Web para produccion

```bash
cd frontend
flutter build web --release --base-href /TFM/

# Copiar build al VPS
scp -r build/web/* root@<IP_VPS>:/opt/inmufacil/frontend/build/web/
```

### Actualizacion de la aplicacion

```bash
cd /opt/inmufacil
git pull origin develop
docker compose down
docker compose up -d --build
```

---

## Google OAuth — Configuracion

Para que el login con Google funcione en produccion:

1. Ir a [Google Cloud Console](https://console.cloud.google.com)
2. Crear proyecto → APIs y Servicios → Credenciales
3. Crear **OAuth 2.0 Web Client ID**
4. Agregar origenes autorizados:
   - `https://inmufacil.com`
   - `http://localhost:8001` (desarrollo)
5. Agregar URIs de redireccion autorizados:
   - `https://inmufacil.com/TFM`
   - `http://localhost:8001`
6. Copiar el **Web Client ID** y ponerlo en:
   - `.env` → `GOOGLE_WEB_CLIENT_ID=...`
   - `frontend/.env` → `GOOGLE_WEB_CLIENT_ID=...`

---

## Seguridad en Produccion

- Cambiar `SECRET_KEY_JWT` por un valor de alta entropia: `openssl rand -base64 32`
- Cambiar `INMUFACIL_MASTER_KEY` por una clave nueva: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`
- Rotar contrasenas de base de datos
- Habilitar firewall (ufw): permitir solo 80, 443, 22
- Deshabilitar acceso root SSH por contrasena (usar claves SSH)
- Nunca commitear `.env` al repositorio

---

## Monitoreo

```bash
# Logs del backend en tiempo real
docker compose logs -f backend

# Logs de PostgreSQL
docker compose logs -f db

# Estado de contenedores
docker compose ps

# Espacio en disco
df -h
```
