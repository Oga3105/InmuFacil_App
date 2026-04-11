#!/usr/bin/env bash
# =============================================================================
# deploy-backend.sh — Despliegue del Backend FastAPI a produccion
#
# Uso:
#   & "C:\Program Files\Git\bin\bash.exe" deploy-backend.sh
#
# Que hace:
#   1. Avisa si hay cambios sin commitear (no bloquea, pero advierte).
#   2. Sube SOLO el codigo del backend al servidor (NUNCA el docker-compose.yml).
#   3. (Opcional) Actualiza el .env del servidor parcheando valores de produccion.
#   4. Reconstruye SOLO la imagen Docker del backend usando el compose del servidor.
#   5. Reinicia SOLO el contenedor backend. La BD NO se toca.
#   6. Reconecta el backend a la red de nginx con alias correcto.
#
# IMPORTANTE:
#   El docker-compose.yml del servidor es el de produccion y NUNCA se sobreescribe.
#   El .env del servidor esta configurado para produccion. Responde N a la pregunta
#   del .env salvo que hayas anadido variables nuevas al proyecto.
# =============================================================================
set -euo pipefail

SERVER="root@87.106.247.84"
REMOTE_APP_DIR="/opt/inmufacil"
# Nombre de BD en produccion
PROD_DB_NAME="inmufacil_prod"
# Red que comparten nginx y backend (nginx resuelve 'backend' en esta red)
NGINX_NETWORK="app_inmufacil_net"
# Red interna del compose (backend <-> DB)
COMPOSE_NETWORK="inmufacil_inmufacil_net"

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
# PASO 2 — Sincronizar SOLO el codigo del backend
# NUNCA se sube docker-compose.yml (el servidor tiene el de produccion).
# ---------------------------------------------------------------------------
echo "[2/5] Sincronizando codigo del backend al servidor..."
echo ""

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "mkdir -p $REMOTE_APP_DIR/backend"

# Solo el codigo: backend/ y requirements.txt
# El docker-compose.yml del servidor NO se toca.
scp -o StrictHostKeyChecking=accept-new \
  -r backend "$SERVER:$REMOTE_APP_DIR/"

# requirements.txt solo si existe en raiz (puede estar en backend/)
if [ -f "requirements.txt" ]; then
  scp -o StrictHostKeyChecking=accept-new \
    requirements.txt "$SERVER:$REMOTE_APP_DIR/"
fi

echo "  Codigo sincronizado."

# ---------------------------------------------------------------------------
# PASO 3 — Actualizacion del .env (RESPONDE N EN CONDICIONES NORMALES)
# ---------------------------------------------------------------------------
echo ""
echo "  AVISO: El .env del servidor esta configurado para produccion."
echo "  Responde S solo si has anadido nuevas variables al proyecto."
read -rp "[3/5] Actualizar el .env del servidor con el .env local? (s/N): " update_env
if [[ "$update_env" =~ ^[sS]$ ]]; then
  if [ ! -f ".env" ]; then
    echo "  ERROR: No se encuentra .env en la raiz del proyecto."
    echo "  El .env del servidor NO ha sido modificado."
  else
    scp -o StrictHostKeyChecking=accept-new \
      .env "$SERVER:$REMOTE_APP_DIR/.env"
    ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
      "sed -i 's|localhost:[0-9]*|db:5432|g' $REMOTE_APP_DIR/.env && \
       sed -i 's|/inmufacil_db|/$PROD_DB_NAME|g' $REMOTE_APP_DIR/.env"
    echo "  .env actualizado. Verificando DATABASE_URL:"
    ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
      "grep DATABASE_URL $REMOTE_APP_DIR/.env | head -1"
  fi
else
  echo "  .env del servidor mantenido sin cambios (correcto)."
fi
echo ""

# ---------------------------------------------------------------------------
# PASO 4 — Reconstruir imagen Docker usando el compose del servidor
# ---------------------------------------------------------------------------
echo "[4/5] Reconstruyendo imagen Docker del backend..."
echo "  (Puede tardar 2-5 minutos si cambiaron dependencias en requirements.txt)"
echo ""

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "cd $REMOTE_APP_DIR && docker compose build backend"

# ---------------------------------------------------------------------------
# PASO 5 — Reiniciar backend + reconectar redes
#
# Tras recrear el contenedor con docker compose, este queda en la red interna
# del compose (COMPOSE_NETWORK). Hay que conectarlo ademas a NGINX_NETWORK
# con el alias 'backend' para que nginx pueda resolverlo por nombre.
# ---------------------------------------------------------------------------
echo ""
echo "[5/5] Reiniciando contenedor del backend (BD intacta)..."

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "docker stop inmufacil_backend 2>/dev/null || true && \
   docker rm inmufacil_backend 2>/dev/null || true && \
   cd $REMOTE_APP_DIR && \
   docker compose up -d --no-deps backend && \
   docker network disconnect $NGINX_NETWORK inmufacil_backend 2>/dev/null || true && \
   docker network connect --alias backend $NGINX_NETWORK inmufacil_backend && \
   docker exec inmufacil_proxy nginx -s reload && \
   echo '' && \
   echo '--- Estado de contenedores ---' && \
   docker ps --filter name=inmufacil --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "============================================"
echo "  BACKEND DEPLOY COMPLETADO"
echo "  Commit desplegado: $COMMIT ($BRANCH)"
echo "============================================"
echo ""
