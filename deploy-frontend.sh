#!/usr/bin/env bash
# =============================================================================
# deploy-frontend.sh — Despliegue de Flutter Web a produccion
#
# Uso desde la raiz del proyecto:
#   bash deploy-frontend.sh
#
# Que hace:
#   1. Construye el .env de produccion desde el .env local (sobrescribiendo
#      ENABLE_LOGGING y API_BASE_URL con valores de produccion).
#   2. Compila Flutter web en modo release con base-href /TFM/.
#   3. Restaura el .env local original.
#   4. Sube el build al servidor via SCP.
#   5. Ajusta permisos y recarga nginx (una sola sesion SSH).
#
# Prerequisitos:
#   - flutter en PATH
#   - ssh y scp disponibles (Git Bash / WSL en Windows)
#   - frontend/.env con GOOGLE_WEB_CLIENT_ID relleno
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuracion
# ---------------------------------------------------------------------------
SERVER="root@87.106.247.84"
REMOTE_PATH="/opt/inmufacil/frontend/build/TFM"
FRONTEND_DIR="frontend"
ENV_FILE="$FRONTEND_DIR/.env"
ENV_BACKUP="$FRONTEND_DIR/.env.deploy_backup"

# SSH multiplexing: pide la clave una sola vez, reutiliza la conexion 5 min
SSH_CTL="/tmp/inmufacil-frontend-deploy-$$"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$SSH_CTL -o ControlPersist=300 -o StrictHostKeyChecking=accept-new"

# ---------------------------------------------------------------------------
# Limpieza garantizada al salir (error o exito)
# ---------------------------------------------------------------------------
cleanup() {
  # Restaurar .env local si el backup existe
  if [ -f "$ENV_BACKUP" ]; then
    mv "$ENV_BACKUP" "$ENV_FILE"
    echo "[cleanup] .env local restaurado."
  fi
  # Cerrar socket SSH multiplexado
  ssh $SSH_OPTS -O exit "$SERVER" 2>/dev/null || true
  rm -f "$SSH_CTL"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Comprobaciones previas
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "  DEPLOY FRONTEND — InmuFacil"
echo "  Destino: $SERVER:$REMOTE_PATH"
echo "============================================"
echo ""

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: No se encuentra $ENV_FILE. Crea el archivo antes de desplegar."
  exit 1
fi

if ! command -v flutter &>/dev/null; then
  echo "ERROR: Flutter no esta en el PATH."
  exit 1
fi

# ---------------------------------------------------------------------------
# PASO 1 — Construir .env de produccion
# ---------------------------------------------------------------------------
echo "[1/5] Preparando entorno de produccion..."

# Leer GOOGLE_WEB_CLIENT_ID del .env local actual
GCID=$(grep "^GOOGLE_WEB_CLIENT_ID=" "$ENV_FILE" | cut -d= -f2- || echo "")
if [ -z "$GCID" ]; then
  echo "ADVERTENCIA: GOOGLE_WEB_CLIENT_ID no encontrado en $ENV_FILE."
  echo "  La build se generara sin Google OAuth."
fi

# Hacer backup del .env local
cp "$ENV_FILE" "$ENV_BACKUP"

# Escribir .env de produccion (baked-in en build/web/assets/.env)
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
  flutter build web --release --base-href /TFM/
)
echo "  Build completado: $FRONTEND_DIR/build/web/"

# ---------------------------------------------------------------------------
# PASO 3 — Restaurar .env local
# ---------------------------------------------------------------------------
echo "[3/5] Restaurando entorno local..."
mv "$ENV_BACKUP" "$ENV_FILE"
echo "  .env local restaurado."

# ---------------------------------------------------------------------------
# PASO 4 — Subir build al servidor
# ---------------------------------------------------------------------------
echo ""
echo "[4/5] Subiendo build al servidor..."
echo "  (Se pedira la contrasena SSH del servidor)"
echo ""

# Abrir sesion SSH multiplexada (primera vez pide contrasena)
ssh $SSH_OPTS "$SERVER" "mkdir -p $REMOTE_PATH"

# Subir todos los archivos del build
scp -o "ControlPath=$SSH_CTL" -o "ControlMaster=no" \
  -r "$FRONTEND_DIR/build/web/"* "$SERVER:$REMOTE_PATH/"

echo "  Archivos subidos."

# ---------------------------------------------------------------------------
# PASO 5 — Permisos + recarga nginx
# ---------------------------------------------------------------------------
echo "[5/5] Ajustando permisos y recargando nginx..."

ssh -o "ControlPath=$SSH_CTL" -o "ControlMaster=no" "$SERVER" \
  "find $REMOTE_PATH -type d -exec chmod 755 {} \; && \
   find $REMOTE_PATH -type f -exec chmod 644 {} \; && \
   docker exec inmufacil_proxy nginx -s reload"

echo ""
echo "============================================"
echo "  FRONTEND DEPLOY COMPLETADO"
echo "  URL: https://inmufacil.com/TFM/"
echo "============================================"
echo ""
