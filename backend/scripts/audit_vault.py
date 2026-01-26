"""
@Shield - Vault Audit Script V3 (Debug Mode)

Provides transparency into encrypted vault data.
No try/except on imports to show real errors.

Usage:
    python -m backend.scripts.audit_vault
"""

import sys
import os

# --- 1. CARGA NATIVA DE VARIABLES .ENV ---
def load_env_native():
    env_path = os.path.join(os.getcwd(), '.env')
    if not os.path.exists(env_path):
        print("⚠️ .env no encontrado.")
        return
    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, value = line.split('=', 1)
            os.environ[key.strip()] = value.strip().strip("'").strip('"')

load_env_native()

# --- 2. CONFIGURACIÓN DE RUTAS ---
# Añadimos el directorio actual al path para que Python encuentre 'backend'
sys.path.append(os.getcwd())

print("⚙️ Cargando módulos del sistema...")

# --- 3. IMPORTS (Sin Try/Except para ver errores reales) ---
from sqlalchemy import text  # Necesario para consultas raw en SQLA 2.0
from backend.database import SessionLocal  # Use SessionLocal directly
from backend.core.security import decrypt_data

def audit_vault():
    print("\n🔍 INICIANDO AUDITORÍA FORENSE DE LA BÓVEDA")
    print("=" * 60)

    key = os.getenv("INMUFACIL_MASTER_KEY")
    if not key:
        print("❌ ERROR: INMUFACIL_MASTER_KEY no encontrada en .env")
        return
    
    print("🔐 Llave Maestra cargada.")

    # Create database session
    db = SessionLocal()
    try:
        print("📡 Conectado a Base de Datos. Consultando...")
        
        # CORRECCIÓN: Usamos text() para la consulta SQL
        sql = text("SELECT id, dni_encrypted, status FROM kyc_verifications ORDER BY id DESC LIMIT 5")
        result = db.execute(sql)
        rows = result.fetchall()

        if not rows:
            print("📭 La tabla 'kyc_verifications' está vacía.")
            return
        
        print(f"\n📊 Encontrados {len(rows)} registros:\n")
        
        for row in rows:
            # Acceso seguro por índice
            rid, encrypted, status = row[0], row[1], row[2]

            print(f"{'─' * 60}")
            print(f"📄 ID: {rid} | ESTADO: {status}")
            print(f"   🔒 RAW: {str(encrypted)[:15]}...")
            
            try:
                decrypted = decrypt_data(encrypted)
                print(f"   🔓 REAL: {decrypted}")
                print("   ✅ Integridad OK")
            except Exception as e:
                print(f"   ❌ Error Descifrado: {e}")
        
        print(f"{'─' * 60}")

    except Exception as e:
        print(f"\n❌ ERROR DE EJECUCIÓN: {e}")
        print("CONSEJO: Verifica que Docker esté corriendo y la base de datos exista.")
        import traceback
        traceback.print_exc()
    
    finally:
        db.close()
    
    print("\n" + "=" * 60)
    print("✅ AUDITORÍA FINALIZADA")
    print("=" * 60)

if __name__ == "__main__":
    print("\n🔐 InmuFácil Vault Audit Tool")
    print("Provides transparency into encrypted data storage\n")
    
    try:
        audit_vault()
    except KeyboardInterrupt:
        print("\n⚠️ Auditoría interrumpida")
    except Exception as e:
        print(f"\n❌ Error fatal: {e}")
        import traceback
        traceback.print_exc()
