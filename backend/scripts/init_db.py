# -*- coding: utf-8 -*-
import sys
import os
import time
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configurar codificación UTF-8 para Windows y desactivar lectura de archivos de config
if sys.platform == "win32":
    os.environ['PGCLIENTENCODING'] = 'latin-1'
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
    logger.info("[INFO] Intentando conectar a PostgreSQL en Docker...")
    
    # Reintento simple por si la DB está despertando
    db_up = False
    for i in range(5):
        try:
            with engine.connect() as connection:
                logger.info("[OK] Conexion establecida con exito!")
                db_up = True
                break
        except OperationalError as e:
            logger.warning(f"[WAIT] La base de datos esta calentando... (Intento {i+1}/5)")
            logger.debug(f"[DEBUG] Error: {e}")
            time.sleep(2)
        except Exception as e:
            logger.error(f"[ERROR] Error inesperado: {type(e).__name__}: {e}")
            return
    
    if not db_up:
        logger.error("[ERROR] No se pudo conectar a Postgres. Revisa si Docker esta corriendo.")
        return

    logger.info("[INFO] Creando tablas en la base de datos nueva...")
    Base.metadata.create_all(bind=engine)
    logger.info("[OK] Tablas creadas (Users, etc.)")

    # Crear usuario Admin
    db = SessionLocal()
    try:
        if not db.query(User).filter(User.email == "admin@inmufacil.com").first():
            logger.info("[INFO] Creando usuario Admin inicial...")
            admin = User(
                email="admin@inmufacil.com",
                hashed_password=get_password_hash("Admin123!"),
                full_name="Super Admin",
                user_type=UserType.PARTICULAR  # Usando el enum correcto
            )
            db.add(admin)
            db.commit()
            logger.info("[OK] Usuario Admin creado: admin@inmufacil.com / Admin123!")
        else:
            logger.info("[INFO] El usuario Admin ya existe.")
    except Exception as e:
        logger.error(f"[ERROR] Error creando usuario: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
