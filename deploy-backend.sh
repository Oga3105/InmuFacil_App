#!/usr/bin/env bash
# =============================================================================
# deploy-backend.sh — Despliegue del Backend FastAPI a produccion
#
# Uso desde la raiz del proyecto:
#   bash deploy-backend.sh
#
# Que hace:
#   1. Avisa si hay cambios sin commitear (no bloquea, pero advierte).
#   2. Sincroniza el codigo del backend al servidor via rsync (incremental).
#   3. Pregunta si actualizar el .env del servidor (nunca lo sobreescribe
#      sin confirmacion explicita).
#   4. Reconstruye SOLO la imagen Docker del backend.
#   5. Reinicia SOLO el contenedor del backend (inmufacil_backend).
#      La base de datos (inmufacil_postgres) NO se toca.
#
# Prerequisitos:
#   - rsync disponible (incluido en Git Bash / WSL)
#   - ssh disponible
#   - docker-compose.prod.yml en la raiz del proyecto
#   - El servidor debe tener Docker y docker-compose instalados
#
# Directorio remoto del codigo: /opt/inmufacil/app/
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuracion
# ---------------------------------------------------------------------------
SERVER="root@87.106.247.84"
REMOTE_APP_DIR="/opt/inmufacil/app"

# SSH multiplexing: pide la clave una sola vez, reutiliza la conexion 10 min
SSH_CTL="/tmp/inmufacil-backend-deploy-$$"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$SSH_CTL -o ControlPersist=600 -o StrictHostKeyChecking=accept-new"

# ---------------------------------------------------------------------------
# Limpieza garantizada al salir
# ---------------------------------------------------------------------------
cleanup() {
  ssh $SSH_OPTS -O exit "$SERVER" 2>/dev/null || true
  rm -f "$SSH_CTL"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Cabecera
# ---------------------------------------------------------------------------
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
  echo "  Solo se subira el codigo commiteado y los archivos del working tree."
  read -rp "  Continuar igualmente? (s/N): " confirm
  [[ "$confirm" =~ ^[sS]$ ]] || { echo "Deploy cancelado."; exit 1; }
fi
echo ""

# ---------------------------------------------------------------------------
# PASO 2 — Sincronizacion de codigo al servidor
# ---------------------------------------------------------------------------
echo "[2/5] Sincronizando codigo del backend al servidor..."
echo "  (Se pedira la contrasena SSH del servidor)"
echo ""

# Abrir sesion SSH multiplexada (primera vez pide contrasena)
ssh $SSH_OPTS "$SERVER" "mkdir -p $REMOTE_APP_DIR"

# rsync incremental: solo sube lo que cambio
# Excluye entornos virtuales, caches, frontend, datos y secretos
rsync -avz --progress \
  --exclude '.git' \
  --exclude '.venv' \
  --exclude '__pycache__' \
  --exclude '*.pyc' \
  --exclude '*.pyo' \
  --exclude '*.dump' \
  --exclude '*.log' \
  --exclude 'frontend/' \
  --exclude 'uploads/' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude 'backup_*.sql' \
  --exclude 'fix_*.sql' \
  --exclude '.agents/' \
  --exclude 'docs/' \
  -e "ssh -o ControlPath=$SSH_CTL -o ControlMaster=no" \
  . "$SERVER:$REMOTE_APP_DIR/"

echo ""
echo "  Codigo sincronizado."

# ---------------------------------------------------------------------------
# PASO 3 — Actualizacion del .env en el servidor (opcional)
# ---------------------------------------------------------------------------
echo ""
read -rp "[3/5] Actualizar el .env del servidor con el .env local? (s/N): " update_env
if [[ "$update_env" =~ ^[sS]$ ]]; then
  if [ ! -f ".env" ]; then
    echo "  ERROR: No se encuentra .env en la raiz del proyecto."
    echo "  El .env del servidor NO ha sido modificado."
  else
    echo "  Subiendo .env al servidor..."
    scp -o "ControlPath=$SSH_CTL" -o "ControlMaster=no" \
      .env "$SERVER:$REMOTE_APP_DIR/.env"
    echo "  .env del servidor actualizado."
  fi
else
  echo "  .env del servidor mantenido sin cambios."
fi
echo ""

# ---------------------------------------------------------------------------
# PASO 4 — Reconstruir imagen Docker del backend
# ---------------------------------------------------------------------------
echo "[4/5] Reconstruyendo imagen Docker del backend en el servidor..."
echo "  (Puede tardar 2-5 minutos si cambiaron dependencias)"
echo ""

ssh -o "ControlPath=$SSH_CTL" -o "ControlMaster=no" "$SERVER" \
  "cd $REMOTE_APP_DIR && \
   docker-compose -f docker-compose.prod.yml build backend"

echo ""
echo "  Imagen reconstruida."

# ---------------------------------------------------------------------------
# PASO 5 — Reiniciar SOLO el backend (BD intacta)
# ---------------------------------------------------------------------------
echo "[5/5] Reiniciando contenedor del backend (la BD NO se toca)..."

ssh -o "ControlPath=$SSH_CTL" -o "ControlMaster=no" "$SERVER" \
  "cd $REMOTE_APP_DIR && \
   docker-compose -f docker-compose.prod.yml up -d --no-deps backend && \
   echo '--- Estado de contenedores ---' && \
   docker ps --filter name=inmufacil --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "============================================"
echo "  BACKEND DEPLOY COMPLETADO"
echo "  Commit desplegado: $COMMIT ($BRANCH)"
echo "============================================"
echo ""
