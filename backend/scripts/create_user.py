"""
Emergency User Creation Script - Database Bypass

@Architect: Direct database insertion for emergency access
@Shield: Password hashing maintained

Usage:
    python -m backend.scripts.create_user
"""

import sys
import os

# Configure path to see 'backend' module
sys.path.append(os.getcwd())

from backend.database import SessionLocal, engine, Base
from backend.security import get_password_hash
from backend.models import User, UserType, DNIStatus
from sqlalchemy.exc import IntegrityError


def inject_user():
    """
    Inject admin user directly into database, bypassing API layer.
    """
    print("\n💉 INICIANDO INYECCIÓN MANUAL DE USUARIO...")
    print("=" * 60)

    # Step A: Ensure tables exist (Database repair)
    print("🛠️  Verificando/Creando tablas en Base de Datos...")
    Base.metadata.create_all(bind=engine)
    print("✅ Estructura de base de datos verificada.")

    # Step B: Create user object
    print("\n👤 Creando usuario de prueba...")
    hashed_pw = get_password_hash("Admin123!")
    
    new_user = User(
        email="admin@inmufacil.com",
        hashed_password=hashed_pw,
        full_name="Admin TFM",
        user_type=UserType.PROFESIONAL,
        dni_status=DNIStatus.PENDIENTE,
        email_verified=False,
        dni_verified=False,
        failed_upload_attempts=0
    )

    # Step C: Insert into database
    db = SessionLocal()
    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        print(f"\n✅ USUARIO CREADO CON ÉXITO.")
        print(f"   ID: {new_user.id}")
        print(f"   Email: {new_user.email}")
        print(f"   Tipo: {new_user.user_type.value}")
        print(f"   Contraseña: Admin123!")
        print("\n📋 Credenciales para login:")
        print(f"   Email: {new_user.email}")
        print(f"   Password: Admin123!")
        
    except IntegrityError as e:
        db.rollback()
        print("\n⚠️  AVISO: El usuario 'admin@inmufacil.com' ya existe.")
        print("   (Esto es bueno, significa que la BD está operativa).")
        print(f"   Detalles: {str(e)}")
        
    except Exception as e:
        db.rollback()
        print(f"\n❌ ERROR FATAL AL INSERTAR: {e}")
        print("   Revisa si el modelo 'User' tiene campos obligatorios que faltan.")
        import traceback
        traceback.print_exc()
        
    finally:
        db.close()

    print("\n" + "=" * 60)
    print("✅ SCRIPT COMPLETADO")
    print("=" * 60)


if __name__ == "__main__":
    inject_user()
