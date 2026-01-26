"""
@Shield - Vault Audit Script (Native .env Loading - No External Dependencies)

Provides transparency into encrypted vault data.
Allows authorized personnel to decrypt and view stored verification data.

Security Features:
- Native .env parsing (no python-dotenv needed)
- Read-only operations (no modifications)
- Requires INMUFACIL_MASTER_KEY from .env
- Displays decrypted data for verification

Usage:
    python -m backend.scripts.audit_vault
"""

import sys
import os

# ============================================================================
# STEP 1: NATIVE .ENV LOADING (No external dependencies)
# ============================================================================
def load_env_native():
    """
    Read .env file line by line without external dependencies.
    Parses KEY=VALUE format and sets environment variables.
    """
    env_path = os.path.join(os.getcwd(), '.env')
    if not os.path.exists(env_path):
        print("⚠️  WARNING: .env file not found in project root.")
        return

    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            # Ignore comments and empty lines
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, value = line.split('=', 1)
                # Clean quotes and whitespace
                key = key.strip()
                value = value.strip().strip("'").strip('"')
                # Only set if not already in environment
                if key not in os.environ:
                    os.environ[key] = value

# Execute native .env loading BEFORE importing project modules
load_env_native()

# ============================================================================
# STEP 2: PATH ADJUSTMENT
# ============================================================================
sys.path.append(os.getcwd())

# ============================================================================
# STEP 3: IMPORTS (After .env is loaded)
# ============================================================================
try:
    from backend.database import SessionLocal
    from backend.core.security import decrypt_data
    from datetime import datetime
except ImportError as e:
    print(f"\n❌ ENVIRONMENT ERROR: Missing library '{e.name}'.")
    print("   Run: pip install sqlalchemy cryptography")
    sys.exit(1)


def audit_vault():
    """
    Audit the encryption vault by querying database and decrypting stored data.
    
    @Shield: Vault transparency for authorized personnel
    """
    print("\n🔍 INICIANDO AUDITORÍA FORENSE DE LA BÓVEDA (Modo Nativo)...")
    print("=" * 60)
    
    # ========================================================================
    # SECURITY CHECK: Verify master key is available
    # ========================================================================
    key = os.getenv("INMUFACIL_MASTER_KEY")
    if not key:
        print("❌ ERROR CRÍTICO: No se detectó 'INMUFACIL_MASTER_KEY' en el .env")
        print("   Asegúrate de que el archivo .env existe y contiene:")
        print("   INMUFACIL_MASTER_KEY=your_base64_key_here")
        return False
    
    print("🔐 Llave Maestra cargada en memoria.")
    print(f"📅 Fecha de auditoría: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # ========================================================================
    # DATABASE QUERY: Fetch encrypted verification records
    # ========================================================================
    db = SessionLocal()
    try:
        # Query last 5 KYC verifications
        result = db.execute(
            "SELECT id, dni_encrypted, status FROM kyc_verifications ORDER BY id DESC LIMIT 5"
        )
        rows = result.fetchall()
        
        if not rows:
            print("\n📭 La base de datos está vacía. Sube un DNI para ver datos aquí.")
            return True
        
        print(f"\n📊 Encontrados {len(rows)} registros de verificación:\n")
        
        # ================================================================
        # DECRYPT AND DISPLAY: Each verification record
        # ================================================================
        for row in rows:
            verif_id = row[0]
            encrypted_data = row[1]
            status = row[2]
            
            print(f"{'─' * 60}")
            print(f"📄 REGISTRO ID: {verif_id} | ESTADO: {status}")
            
            # Show preview of encrypted data
            preview = str(encrypted_data)[:15] + "..." if encrypted_data else "N/A"
            print(f"   🔒 Cifrado: {preview}")
            
            # Attempt decryption (proof of concept)
            try:
                decrypted = decrypt_data(encrypted_data)
                print(f"   🔓 REAL:    {decrypted}")
                print("   ✅ Integridad: VERIFICADA")
                
            except Exception as e:
                print(f"   ❌ ERROR DESCIFRADO: {e}")
                print("      (La clave actual no coincide con la que cifró este dato)")
        
        print(f"{'─' * 60}")
        
    except Exception as e:
        print(f"\n❌ Error conectando a la BD: {e}")
        print("   Verifica que la base de datos esté accesible.")
        return False
        
    finally:
        db.close()
    
    # ========================================================================
    # AUDIT COMPLETE
    # ========================================================================
    print("\n" + "=" * 60)
    print("✅ AUDITORÍA FINALIZADA")
    print("=" * 60)
    
    return True


if __name__ == "__main__":
    print("\n🔐 InmuFácil Vault Audit Tool")
    print("Provides transparency into encrypted data storage\n")
    
    try:
        success = audit_vault()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Auditoría interrumpida por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error fatal: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
