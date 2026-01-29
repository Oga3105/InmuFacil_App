from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

# 1.# Cargamos variables de entorno (.env)
load_dotenv()

# Obtenemos la URL. Si no existe, fallback a SQLite local (por seguridad)
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sql_app.db")

# Configuración del Motor
# Postgres no necesita 'check_same_thread', SQLite sí.
if "sqlite" in SQLALCHEMY_DATABASE_URL:
    print(f"[WARNING] MODO BASE DE DATOS: SQLite Local ({SQLALCHEMY_DATABASE_URL})")
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )
else:
    print("[INFO] MODO BASE DE DATOS: PostgreSQL (Docker)")
    # Usar parámetros explícitos para evitar problemas de encoding en Windows
    from sqlalchemy.engine.url import URL
    db_url = URL.create(
        drivername="postgresql+psycopg2",
        username="inmufacil_user",
        password="passwordSeguro123",
        host="127.0.0.1",
        port=5432,
        database="inmufacil_db",
        query={"client_encoding": "latin1"}
    )
    engine = create_engine(db_url)

# 4. Crear Sesión y Base
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 5. Dependencia para inyección (Dependency Injection)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
