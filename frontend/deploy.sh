#!/usr/bin/env bash
set -e

SERVER="root@87.106.247.84"
REMOTE_PATH="/opt/inmufacil/frontend/build/TFM"

echo "Preparing production environment..."
# Backup local .env and inject production config for the build
cp .env .env.local_backup
cat > .env << ENVEOF
API_BASE_URL=https://www.inmufacil.com/api/v1
API_TIMEOUT=30000
ENABLE_LOGGING=false
GOOGLE_WEB_CLIENT_ID=$(grep GOOGLE_WEB_CLIENT_ID .env.local_backup | cut -d= -f2-)
ENVEOF

echo "Building Flutter web..."
flutter build web --release --base-href /TFM/

echo "Restoring local environment..."
mv .env.local_backup .env

echo "Uploading to server..."
scp -r build/web/* "$SERVER:$REMOTE_PATH/"

echo "Fixing permissions..."
ssh "$SERVER" "find $REMOTE_PATH -type d -exec chmod 755 {} \; && find $REMOTE_PATH -type f -exec chmod 644 {} \; && docker exec inmufacil_proxy nginx -s reload"

echo "Deploy complete."
