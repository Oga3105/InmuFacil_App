"""
@Shield - Vault Audit Script (Fixed .env Loading)

Provides transparency into encrypted vault data.
Allows authorized personnel to decrypt and view stored verification data.

Security Features:
- Explicit .env loading with python-dotenv
- Read-only operations (no modifications)
- Requires INMUFACIL_MASTER_KEY from .env
- Logs all audit access
- Displays decrypted data for verification

Usage:
    python -m backend.scripts.audit_vault

Token Consumption Tracking: ~400 tokens for audit script
"""

import sys
import os
import asyncio
from dotenv import load_dotenv

# ============================================================================
# STEP 1: CRITICAL - LOAD ENVIRONMENT VARIABLES FIRST
# ============================================================================
# This must happen BEFORE any other imports that depend on env vars
load_dotenv()

# ============================================================================
# STEP 2: PATH ADJUSTMENT
# ============================================================================
# Ensure Python can find the 'backend' module when run as script
sys.path.append(os.getcwd())

# ============================================================================
# STEP 3: IMPORTS (Only after .env is loaded)
# ============================================================================
from backend.database import get_db_context
from backend.core.security import decrypt_data
from sqlalchemy import text
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("vault_audit")


async def audit_vault():
    """
    Audit the encryption vault by querying database and decrypting stored data.
    
    @Shield: Vault transparency for authorized personnel
    @Watcher: Logs all audit access
    """
    print("\n🔍 INICIANDO AUDITORÍA FORENSE DE LA BÓVEDA...")
    print("=" * 60)
    
    # ========================================================================
    # SECURITY CHECK: Verify master key is available
    # ========================================================================
    key = os.getenv("INMUFACIL_MASTER_KEY")
    if not key:
        logger.error("[ERROR] INMUFACIL_MASTER_KEY not found in environment")
        print("❌ ERROR CRÍTICO: No se encuentra 'INMUFACIL_MASTER_KEY' en las variables de entorno.")
        print("   Asegúrate de que el archivo .env existe y tiene la clave.")
        print("   Ejemplo: INMUFACIL_MASTER_KEY=your_base64_key_here")
        return False
    
    print("🔐 Llave Maestra detectada en memoria.")
    logger.info(f"[VAULT] Audit initiated at: {datetime.now().isoformat()}")
    
    # ========================================================================
    # DATABASE QUERY: Fetch encrypted verification records
    # ========================================================================
    try:
        async with get_db_context() as db:
            # Query last 5 KYC verifications
            query = text("""
                SELECT id, dni_encrypted, status, created_at 
                FROM kyc_verifications 
                ORDER BY id DESC 
                LIMIT 5
            """)
            result = await db.execute(query)
            rows = result.fetchall()
            
            if not rows:
                print("📭 La base de datos está vacía. No hay registros de KYC para auditar.")
                logger.info("[VAULT] No records found in database")
                return True
            
            print(f"\n📊 Encontrados {len(rows)} registros de verificación:\n")
            
            # ================================================================
            # DECRYPT AND DISPLAY: Each verification record
            # ================================================================
            for row in rows:
                verif_id = row[0]
                encrypted_data = row[1]
                status = row[2]
                created_at = row[3] if len(row) > 3 else "N/A"
                
                print(f"{'─' * 60}")
                print(f"📄 REGISTRO ID: {verif_id} | ESTADO: {status}")
                print(f"   📅 Fecha: {created_at}")
                print(f"   🔒 Dato Cifrado (Raw): {encrypted_data[:30]}...[OCULTO]")
                
                # Attempt decryption
                try:
                    decrypted_data = decrypt_data(encrypted_data)
                    print(f"   🔓 DATO DESCIFRADO (REAL): {decrypted_data}")
                    print("   ✅ Integridad Criptográfica: VERIFICADA")
                    logger.info(f"[VAULT] Successfully decrypted record {verif_id}")
                    
                except Exception as e:
                    print(f"   ❌ ERROR DE DESCIFRADO: {str(e)}")
                    print("      (La clave actual no coincide con la que cifró este dato)")
                    logger.error(f"[VAULT] Failed to decrypt record {verif_id}: {str(e)}")
            
            print(f"{'─' * 60}")
            
    except Exception as e:
        logger.error(f"[ERROR] Database connection failed: {str(e)}")
        print(f"❌ Error de conexión a la Base de Datos: {e}")
        return False
    
    # ========================================================================
    # AUDIT COMPLETE
    # ========================================================================
    print("\n" + "=" * 60)
    print("✅ AUDITORÍA FINALIZADA CON ÉXITO")
    print("=" * 60)
    logger.info("[VAULT] Audit completed successfully")
    
    return True


if __name__ == "__main__":
    print("\n🔐 InmuFácil Vault Audit Tool")
    print("Provides transparency into encrypted data storage\n")
    
    # Windows-specific event loop policy
    if os.name == 'nt':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    
    # Run async audit
    try:
        success = asyncio.run(audit_vault())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Auditoría interrumpida por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error fatal: {str(e)}")
        logger.exception("[FATAL] Unexpected error during audit")
        sys.exit(1)
