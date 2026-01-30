from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

# 1. Cargar variables de entorno
load_dotenv()

# 2. Obtener URL de Base de Datos
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sql_app.db")

# 3. Configurar Motor
if "sqlite" in SQLALCHEMY_DATABASE_URL:
    print(f"[WARNING] MODO BASE DE DATOS: SQLite Local ({SQLALCHEMY_DATABASE_URL})")
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )
else:
    print("[INFO] MODO BASE DE DATOS: PostgreSQL (Docker)")
    from sqlalchemy.engine.url import URL
    db_url = URL.create(
        drivername="postgresql+psycopg2",
        username="inmufacil_user",
        password="passwordSeguro123", # Todo: Load from env? keeping hardcoded as in original for now
        host="127.0.0.1",
        port=5432,
        database="inmufacil_db"
    )
    engine = create_engine(db_url)

# 4. Configurar Sesión
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 5. Dependencia para inyección (Dependency Injection)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
