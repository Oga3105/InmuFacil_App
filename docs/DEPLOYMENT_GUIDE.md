# Deployment Guide (VPS Ionos + Docker + Cloudflare)

## 1. Hosting Hardware
- **Proveedor**: VPS Ionos
- **SO**: Ubuntu Linux 22.04 LTS

## 2. Docker & Contenedores
Aplicación completamente contenedorizada mediante `docker-compose.yml`:
- `backend`: Contenedor FastAPI ejecutado con Uvicorn en puerto 8000.
- `database`: Contenedor PostgreSQL con persistencia en Volúmenes.

## 3. Redes y CDN
- **Cloudflare**: Gestiona los DNS, proxifica el tráfico y maneja el cifrado SSL.
- **Cloudflare Tunnel (opcional/recomendado)**: Crea una conexión segura saliente desde el VPS hasta la red de Cloudflare sin abrir puertos entrantes.

## 4. Pasos de Despliegue
```bash
git pull origin main
docker compose down
docker compose up -d --build
```
