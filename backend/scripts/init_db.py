# -*- coding: utf-8 -*-
import sys
import os
import time

# Configurar codificación UTF-8 para Windows y desactivar lectura de archivos de config
if sys.platform == "win32":
    os.environ['PGCLIENTENCODING'] = 'UTF8'
    # Desactivar lectura de archivos de configuración de PostgreSQL
    os.environ['PGSYSCONFDIR'] = ''
    os.environ['PGSERVICEFILE'] = ''

# Añadimos el directorio raíz al path para encontrar los módulos
sys.path.append(os.getcwd())

from sqlalchemy.exc import OperationalError
from backend.database import engine, SessionLocal, Base
from backend.models import User, UserType
from backend.security import get_password_hash

def init_db():
    print("[INFO] Intentando conectar a PostgreSQL en Docker...")
    
    # Reintento simple por si la DB está despertando
    db_up = False
    for i in range(5):
        try:
            with engine.connect() as connection:
                print("[OK] Conexion establecida con exito!")
                db_up = True
                break
        except OperationalError as e:
            print(f"[WAIT] La base de datos esta calentando... (Intento {i+1}/5)")
            print(f"[DEBUG] Error: {e}")
            time.sleep(2)
        except Exception as e:
            print(f"[ERROR] Error inesperado: {type(e).__name__}: {e}")
            return
    
    if not db_up:
        print("[ERROR] No se pudo conectar a Postgres. Revisa si Docker esta corriendo.")
        return

    print("[INFO] Creando tablas en la base de datos nueva...")
    Base.metadata.create_all(bind=engine)
    print("[OK] Tablas creadas (Users, etc.)")

    # Crear usuario Admin
    db = SessionLocal()
    try:
        if not db.query(User).filter(User.email == "admin@inmufacil.com").first():
            print("[INFO] Creando usuario Admin inicial...")
            admin = User(
                email="admin@inmufacil.com",
                hashed_password=get_password_hash("Admin123!"),
                full_name="Super Admin",
                user_type=UserType.PARTICULAR  # Usando el enum correcto
            )
            db.add(admin)
            db.commit()
            print("[OK] Usuario Admin creado: admin@inmufacil.com / Admin123!")
        else:
            print("[INFO] El usuario Admin ya existe.")
    except Exception as e:
        print(f"[ERROR] Error creando usuario: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
