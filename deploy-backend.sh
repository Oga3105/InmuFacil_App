#!/usr/bin/env bash
# =============================================================================
# deploy-backend.sh — Despliegue del Backend FastAPI a produccion
#
# Uso:
#   & "C:\Program Files\Git\bin\bash.exe" deploy-backend.sh
#
# Que hace:
#   1. Avisa si hay cambios sin commitear (no bloquea, pero advierte).
#   2. Crea el directorio remoto si no existe.
#   3. Sincroniza el codigo del backend via scp.
#   4. (Opcional) Actualiza el .env del servidor parcheando valores de produccion.
#   5. Reconstruye SOLO la imagen Docker del backend.
#   6. Reinicia SOLO el contenedor backend. La BD NO se toca.
#   7. Reconecta nginx a la red del backend si es necesario.
#
# IMPORTANTE — Pregunta sobre el .env:
#   Responde N (no) salvo que hayas anadido nuevas variables de entorno al
#   proyecto. El .env del servidor esta configurado para produccion y NO debe
#   sobreescribirse con el .env local (que apunta a localhost).
#   Si respondes S, el script parchea automaticamente DATABASE_URL para Docker.
# =============================================================================
set -euo pipefail

SERVER="root@87.106.247.84"
REMOTE_APP_DIR="/opt/inmufacil"
# Nombre de BD en produccion (distinto al local "inmufacil_db")
PROD_DB_NAME="inmufacil_prod"
# Red Docker compartida entre backend, postgres y nginx
DOCKER_NETWORK="app_inmufacil_net"

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
# PASO 2 — Sincronizar codigo al servidor
# ---------------------------------------------------------------------------
echo "[2/5] Sincronizando codigo del backend al servidor..."
echo ""

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "mkdir -p $REMOTE_APP_DIR/backend"

scp -o StrictHostKeyChecking=accept-new \
  requirements.txt docker-compose.yml "$SERVER:$REMOTE_APP_DIR/"

scp -o StrictHostKeyChecking=accept-new \
  -r backend "$SERVER:$REMOTE_APP_DIR/"

echo "  Codigo sincronizado."

# ---------------------------------------------------------------------------
# PASO 3 — Actualizacion del .env (RESPONDE N EN CONDICIONES NORMALES)
# ---------------------------------------------------------------------------
echo ""
echo "  AVISO: El .env del servidor esta configurado para produccion."
echo "  Responde S solo si has anadido nuevas variables al proyecto."
echo "  En ese caso el script parcheara automaticamente DATABASE_URL."
read -rp "[3/5] Actualizar el .env del servidor con el .env local? (s/N): " update_env
if [[ "$update_env" =~ ^[sS]$ ]]; then
  if [ ! -f ".env" ]; then
    echo "  ERROR: No se encuentra .env en la raiz del proyecto."
    echo "  El .env del servidor NO ha sido modificado."
  else
    scp -o StrictHostKeyChecking=accept-new \
      .env "$SERVER:$REMOTE_APP_DIR/.env"
    # Parche 1: host de BD local -> nombre de servicio Docker
    # Parche 2: nombre de BD local -> nombre de BD de produccion
    ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
      "sed -i 's|localhost:[0-9]*|db:5432|g' $REMOTE_APP_DIR/.env && \
       sed -i 's|/inmufacil_db|/$PROD_DB_NAME|g' $REMOTE_APP_DIR/.env"
    echo "  .env actualizado. DATABASE_URL parcheada para Docker + produccion."
    echo "  Verifica que el resultado es correcto:"
    ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
      "grep DATABASE_URL $REMOTE_APP_DIR/.env | head -1"
  fi
else
  echo "  .env del servidor mantenido sin cambios (correcto)."
fi
echo ""

# ---------------------------------------------------------------------------
# PASO 4 — Reconstruir imagen Docker
# ---------------------------------------------------------------------------
echo "[4/5] Reconstruyendo imagen Docker del backend..."
echo "  (Puede tardar 2-5 minutos si cambiaron dependencias en requirements.txt)"
echo ""

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "cd $REMOTE_APP_DIR && \
   docker compose -f docker-compose.yml build backend"

# ---------------------------------------------------------------------------
# PASO 5 — Reiniciar backend + asegurar que nginx comparte su red
# ---------------------------------------------------------------------------
echo ""
echo "[5/5] Reiniciando contenedor del backend (BD intacta)..."

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "docker stop inmufacil_backend 2>/dev/null || true && \
   docker rm inmufacil_backend 2>/dev/null || true && \
   cd $REMOTE_APP_DIR && \
   docker compose -f docker-compose.yml up -d --no-deps backend && \
   docker network connect $DOCKER_NETWORK inmufacil_backend 2>/dev/null || true && \
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
