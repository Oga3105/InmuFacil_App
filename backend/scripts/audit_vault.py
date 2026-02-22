"""
@Shield - Vault Audit Script V3 (Fused)

Provides transparency into encrypted vault data.
No try/except on imports to show real errors.

Usage:
    python -m backend.scripts.audit_vault
"""

import sys
import os
import logging
from pathlib import Path
from datetime import datetime

# --- 1. CONFIGURACIÓN DE LOGGING ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# --- 2. CARGA NATIVA DE VARIABLES .ENV ---
def load_env_native():
    env_path = os.path.join(os.getcwd(), '.env')
    if not os.path.exists(env_path):
        logger.warning("⚠️ .env no encontrado.")
        return
    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip().strip("'").strip('"')

load_env_native()

# --- 3. CONFIGURACIÓN DE RUTAS ---
# Añadimos el directorio actual al path para que Python encuentre 'backend'
sys.path.append(os.getcwd())

logger.info("⚙️ Cargando módulos del sistema...")

# --- 4. IMPORTS ---
from sqlalchemy import text
from backend.database import SessionLocal, engine, Base
from backend.core.security import decrypt_data, get_master_key

# Import models to register them with SQLAlchemy
import backend.models

# Create tables if they don't exist
logger.info("🔧 Verificando estructura de base de datos...")
Base.metadata.create_all(bind=engine)

def audit_vault():
    logger.info("=" * 60)
    logger.info("🔍 INICIANDO AUDITORÍA FORENSE DE LA BÓVEDA")
    logger.info("=" * 60)

    # Validar Clave Maestra
    try:
        key = get_master_key()
        logger.info(f"🔐 Llave Maestra cargada y validada ({len(key)} bytes).")
    except Exception as e:
        logger.critical(f"❌ ERROR: No se pudo cargar la llave maestra: {e}")
        return

    # Create database session
    db = SessionLocal()
    try:
        logger.info("📡 Conectado a Base de Datos. Consultando...")
        
        # CORRECCIÓN: Tabla real es 'users', columna es 'encrypted_dni'
        sql = text("SELECT id, encrypted_dni, dni_verified FROM users ORDER BY id DESC LIMIT 5")
        result = db.execute(sql)
        rows = result.fetchall()

        if not rows:
            logger.warning("📭 La tabla 'users' está vacía. No hay usuarios registrados.")
            return
        
        logger.info(f"📊 Encontrados {len(rows)} registros recientes:")
        
        for row in rows:
            # Acceso seguro por índice
            rid, encrypted, verified = row[0], row[1], row[2]

            logger.info("-" * 60)
            logger.info(f"📄 USER ID: {rid} | DNI VERIFICADO: {verified}")
            logger.info(f"   🔒 RAW: {str(encrypted)[:15] if encrypted else 'N/A'}...")
            
            if encrypted:
                try:
                    decrypted = decrypt_data(encrypted)
                    logger.info(f"   🔓 REAL: {decrypted}")
                    logger.info("   ✅ Integridad OK")
                except Exception as e:
                    logger.error(f"   ❌ Error Descifrado: {e}")
            else:
                logger.warning(f"   ⚠️  Usuario sin DNI cifrado")
        
        logger.info("-" * 60)

    except Exception as e:
        logger.error(f"❌ ERROR DE EJECUCIÓN: {e}")
        logger.info("CONSEJO: Verifica que Docker esté corriendo y la base de datos exista.")
        import traceback
        logger.error(traceback.format_exc())
    
    finally:
        db.close()
    
    logger.info("=" * 60)
    logger.info("✅ AUDITORÍA FINALIZADA")
    logger.info("=" * 60)

if __name__ == "__main__":
    logger.info("🔐 InmuFácil Vault Audit Tool")
    
    try:
        audit_vault()
    except KeyboardInterrupt:
        logger.warning("⚠️ Auditoría interrumpida")
    except Exception as e:
        logger.critical(f"❌ Error fatal: {e}")