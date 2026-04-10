#!/usr/bin/env bash
# =============================================================================
# deploy-backend.sh — Despliegue del Backend FastAPI a produccion
#
# Uso:
#   & "C:\Program Files\Git\bin\bash.exe" deploy-backend.sh
#
# Que hace:
#   1. Avisa si hay cambios sin commitear (no bloquea, pero advierte).
#   2. Crea el directorio remoto si no existe (clave SSH: 1/4).
#   3. Sincroniza el codigo del backend via rsync incremental (clave SSH: 2/4).
#   4. Pregunta si actualizar el .env del servidor (clave SSH: 3/4 - opcional).
#   5. Reconstruye SOLO la imagen Docker del backend (clave SSH: 4/4).
#   6. Reinicia SOLO el contenedor backend. La BD NO se toca.
# =============================================================================
set -euo pipefail

SERVER="root@87.106.247.84"
REMOTE_APP_DIR="/opt/inmufacil/app"

echo ""
echo "============================================"
echo "  DEPLOY BACKEND — InmuFacil"
echo "  Destino: $SERVER:$REMOTE_APP_DIR"
echo "============================================"
echo ""

# ---------------------------------------------------------------------------
# PASO 1 — Estado del repositorio local
# ---------------------------------------------------------------------------
echo "[1/5] Verificando estado local..."

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo "  Rama: $BRANCH | Commit: $COMMIT"

if ! git diff --quiet HEAD 2>/dev/null; then
  echo ""
  echo "  ADVERTENCIA: Hay cambios sin commitear en el repositorio."
  read -rp "  Continuar igualmente? (s/N): " confirm
  [[ "$confirm" =~ ^[sS]$ ]] || { echo "Deploy cancelado."; exit 1; }
fi
echo ""

# ---------------------------------------------------------------------------
# PASO 2 — Crear directorio remoto + rsync del codigo (clave SSH: 1 y 2)
# ---------------------------------------------------------------------------
echo "[2/5] Sincronizando codigo del backend al servidor..."
echo "  Pedira la clave SSH hasta 4 veces (mkdir, rsync, .env opcional, docker)"
echo ""

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "mkdir -p $REMOTE_APP_DIR/backend"

# Subir solo lo que el Dockerfile necesita para construir la imagen:
#   backend/   — codigo FastAPI
#   requirements.txt — dependencias Python
#   docker-compose.prod.yml — definicion de servicios
#   migrations/ — scripts SQL de referencia
scp -o StrictHostKeyChecking=accept-new \
  requirements.txt docker-compose.prod.yml "$SERVER:$REMOTE_APP_DIR/"

scp -o StrictHostKeyChecking=accept-new \
  -r backend "$SERVER:$REMOTE_APP_DIR/"

echo "  Codigo sincronizado."

# ---------------------------------------------------------------------------
# PASO 3 — Actualizacion del .env en el servidor (opcional, clave SSH: 3)
# ---------------------------------------------------------------------------
echo ""
read -rp "[3/5] Actualizar el .env del servidor con el .env local? (s/N): " update_env
if [[ "$update_env" =~ ^[sS]$ ]]; then
  if [ ! -f ".env" ]; then
    echo "  ERROR: No se encuentra .env en la raiz del proyecto."
    echo "  El .env del servidor NO ha sido modificado."
  else
    scp -o StrictHostKeyChecking=accept-new \
      .env "$SERVER:$REMOTE_APP_DIR/.env"
    echo "  .env del servidor actualizado."
  fi
else
  echo "  .env del servidor mantenido sin cambios."
fi
echo ""

# ---------------------------------------------------------------------------
# PASO 4 — Reconstruir imagen Docker + reiniciar backend (clave SSH: 4)
# ---------------------------------------------------------------------------
echo "[4/5] Reconstruyendo imagen Docker del backend..."
echo "  (Puede tardar 2-5 minutos si cambiaron dependencias en requirements.txt)"
echo ""

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "cd $REMOTE_APP_DIR && \
   docker compose -f docker-compose.prod.yml build backend"

echo ""
echo "[5/5] Reiniciando contenedor del backend (BD intacta)..."

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "cd $REMOTE_APP_DIR && \
   docker compose -f docker-compose.prod.yml up -d --no-deps backend && \
   echo '' && \
   echo '--- Estado de contenedores ---' && \
   docker ps --filter name=inmufacil --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "============================================"
echo "  BACKEND DEPLOY COMPLETADO"
echo "  Commit desplegado: $COMMIT ($BRANCH)"
echo "============================================"
echo ""
