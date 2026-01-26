"""
@Shield - Vault Audit Script (Async with Native .env Loading)

Provides transparency into encrypted vault data.
Allows authorized personnel to decrypt and view stored verification data.

Security Features:
- Native .env parsing (no python-dotenv needed)
- Async database access (compatible with project structure)
- Read-only operations (no modifications)
- Requires INMUFACIL_MASTER_KEY from .env

Usage:
    python -m backend.scripts.audit_vault
"""

import sys
import os
import asyncio

# ============================================================================
# STEP 1: NATIVE .ENV LOADING
# ============================================================================
def load_env_native():
    """Read .env file line by line without external dependencies."""
    env_path = os.path.join(os.getcwd(), '.env')
    if not os.path.exists(env_path):
        return
    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, value = line.split('=', 1)
                value = value.strip().strip("'").strip('"')
                if key not in os.environ:
                    os.environ[key] = value

load_env_native()
sys.path.append(os.getcwd())

# ============================================================================
# STEP 2: IMPORTS
# ============================================================================
try:
    from backend.database import get_db_context
    from backend.core.security import decrypt_data
    from sqlalchemy import text
except ImportError as e:
    print(f"❌ Falta librería: {e.name}")
    print("   Ejecuta: pip install sqlalchemy cryptography")
    sys.exit(1)


async def audit_vault():
    """
    Audit the encryption vault by querying database and decrypting stored data.
    """
    print("\n🔍 INICIANDO AUDITORÍA FORENSE DE LA BÓVEDA...")
    print("=" * 60)

    # Verify master key
    key = os.getenv("INMUFACIL_MASTER_KEY")
    if not key:
        print("❌ ERROR: No hay llave maestra en .env")
        return

    print("🔐 Llave cargada.")
    
    try:
        async with get_db_context() as db:
            # Use text() explicitly for SQLAlchemy 2.0
            sql_query = text(
                "SELECT id, dni_encrypted, status FROM kyc_verifications "
                "ORDER BY id DESC LIMIT 5"
            )
            
            result = await db.execute(sql_query)
            rows = result.fetchall()

            if not rows:
                print("📭 Base de datos vacía. Sube un DNI para ver datos aquí.")
                return
            
            print(f"\n📊 Encontrados {len(rows)} registros:\n")
            
            for row in rows:
                # Access by index for compatibility
                verif_id = row[0]
                encrypted_data = row[1]
                status = row[2]

                print(f"{'─' * 60}")
                print(f"📄 ID: {verif_id} | ESTADO: {status}")
                print(f"   🔒 Cifrado: {str(encrypted_data)[:15]}...")
                
                try:
                    decrypted = decrypt_data(encrypted_data)
                    print(f"   🔓 REAL:    {decrypted}")
                    print("   ✅ Integridad: OK")
                except Exception as e:
                    print(f"   ❌ ERROR DESCIFRADO: {e}")
            
            print(f"{'─' * 60}")

    except Exception as e:
        print(f"❌ Error BD: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "=" * 60)
    print("✅ AUDITORÍA FINALIZADA")
    print("=" * 60)


if __name__ == "__main__":
    print("\n🔐 InmuFácil Vault Audit Tool")
    print("Provides transparency into encrypted data storage\n")
    
    # Windows event loop policy
    if os.name == 'nt':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    
    try:
        asyncio.run(audit_vault())
    except KeyboardInterrupt:
        print("\n⚠️  Auditoría interrumpida")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error fatal: {e}")
        sys.exit(1)
