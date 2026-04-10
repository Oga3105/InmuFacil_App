#!/usr/bin/env bash
# =============================================================================
# deploy-frontend.sh — Despliegue de Flutter Web a produccion
#
# Uso:
#   & "C:\Program Files\Git\bin\bash.exe" deploy-frontend.sh
#
# Que hace:
#   1. Construye el .env de produccion desde el .env local.
#   2. Compila Flutter web en modo release con base-href /TFM/.
#   3. Restaura el .env local original.
#   4. Crea el directorio remoto si no existe (pide clave SSH - 1 vez).
#   5. Sube el build al servidor via SCP (pide clave SSH - 2 vez).
#   6. Ajusta permisos y recarga nginx (pide clave SSH - 3 vez).
# =============================================================================
set -euo pipefail

SERVER="root@87.106.247.84"
REMOTE_PATH="/opt/inmufacil/frontend/build/TFM"
FRONTEND_DIR="frontend"
ENV_FILE="$FRONTEND_DIR/.env"
ENV_BACKUP="$FRONTEND_DIR/.env.deploy_backup"

# ---------------------------------------------------------------------------
# Restaurar .env local si algo falla a mitad
# ---------------------------------------------------------------------------
cleanup() {
  if [ -f "$ENV_BACKUP" ]; then
    mv "$ENV_BACKUP" "$ENV_FILE"
    echo "[cleanup] .env local restaurado."
  fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Cabecera
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "  DEPLOY FRONTEND — InmuFacil"
echo "  Destino: $SERVER:$REMOTE_PATH"
echo "============================================"
echo ""

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: No se encuentra $ENV_FILE."
  exit 1
fi

if ! command -v flutter &>/dev/null; then
  echo "ERROR: Flutter no esta en el PATH."
  exit 1
fi

# ---------------------------------------------------------------------------
# PASO 1 — .env de produccion
# ---------------------------------------------------------------------------
echo "[1/5] Preparando entorno de produccion..."

GCID=$(grep "^GOOGLE_WEB_CLIENT_ID=" "$ENV_FILE" | cut -d= -f2- || echo "")
if [ -z "$GCID" ]; then
  echo "  ADVERTENCIA: GOOGLE_WEB_CLIENT_ID no encontrado en $ENV_FILE."
fi

cp "$ENV_FILE" "$ENV_BACKUP"

cat > "$ENV_FILE" << PROD_ENV
API_BASE_URL=https://inmufacil.com/api/v1
API_TIMEOUT=30000
ENABLE_LOGGING=false
GOOGLE_WEB_CLIENT_ID=${GCID}
PROD_ENV

echo "  .env de produccion generado:"
cat "$ENV_FILE"
echo ""

# ---------------------------------------------------------------------------
# PASO 2 — Compilar Flutter web
# ---------------------------------------------------------------------------
echo "[2/5] Compilando Flutter web (modo release)..."
(
  cd "$FRONTEND_DIR"
  # MSYS_NO_PATHCONV=1 evita que Git Bash convierta /TFM/ a ruta Windows
  MSYS_NO_PATHCONV=1 flutter build web --release --base-href /TFM/
)
echo "  Build completado."

# ---------------------------------------------------------------------------
# PASO 3 — Restaurar .env local
# ---------------------------------------------------------------------------
echo "[3/5] Restaurando entorno local..."
mv "$ENV_BACKUP" "$ENV_FILE"
echo "  .env local restaurado."

# ---------------------------------------------------------------------------
# PASO 4 — Crear directorio remoto si no existe (clave SSH: 1/3)
# ---------------------------------------------------------------------------
echo ""
echo "[4/5] Subiendo build al servidor..."
echo "  Pedira la clave SSH hasta 3 veces (mkdir, scp, permisos+nginx)"
echo ""

ssh -o StrictHostKeyChecking=accept-new "$SERVER" "mkdir -p $REMOTE_PATH"

# SCP del build completo (clave SSH: 2/3)
scp -o StrictHostKeyChecking=accept-new \
  -r "$FRONTEND_DIR/build/web/"* "$SERVER:$REMOTE_PATH/"

echo "  Archivos subidos."

# ---------------------------------------------------------------------------
# PASO 5 — Permisos + recarga nginx (clave SSH: 3/3)
# ---------------------------------------------------------------------------
echo "[5/5] Ajustando permisos y recargando nginx..."

ssh -o StrictHostKeyChecking=accept-new "$SERVER" \
  "find $REMOTE_PATH -type d -exec chmod 755 {} \; && \
   find $REMOTE_PATH -type f -exec chmod 644 {} \; && \
   docker exec inmufacil_proxy nginx -s reload"

echo ""
echo "============================================"
echo "  FRONTEND DEPLOY COMPLETADO"
echo "  URL: https://inmufacil.com/TFM/"
echo "============================================"
echo ""
