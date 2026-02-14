import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from backend.core.logging_config import get_logger

logger = get_logger(__name__)

# Setup path to include backend/ so we can import 'src'
current_dir = os.path.dirname(os.path.abspath(__file__))
# current_dir is .../backend
sys.path.append(current_dir)

# Import directly from src since we added backend/ to sys.path
from src.database import Base, get_db
from src.models.users import User
from src.models.properties import Property, PropertyFeatures, PropertyLegal, PropertyFinancial, PropertyEnvironment
from src.models.enums import (
    PropertyStatus, PropertyType, OperationType, UserType, 
    Orientation, HeatingType, ConservationState, EnergyCertification
)
from src.core.security import get_password_hash

# Configuración de BD directa para el script
# Ajusta esto si tu URL de BD es diferente en .env
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/inmufacil_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def seed_db():
    db = SessionLocal()
    try:
        logger.info("🌱 Iniciando Seeding de Datos...")
        
        # 1. Crear Usuario Propietario (si no existe)
        owner = db.query(User).filter(User.email == "propietario@test.com").first()
        if not owner:
            logger.info("👤 Creando usuario propietario...")
            owner = User(
                email="propietario@test.com",
                hashed_password=get_password_hash("password123"),
                full_name="Propietario Test",
                phone="+34600123456",
                user_type=UserType.PROPIETARIO,
                is_active=True,
                is_verified=True
            )
            db.add(owner)
            db.commit()
            db.refresh(owner)
            logger.info(f"✅ Usuario creado: ID {owner.id}")
        else:
            logger.info(f"ℹ️ Usuario existente: ID {owner.id}")

        # 2. Verificar Propiedades
        count = db.query(Property).count()
        if count > 0:
            logger.info(f"ℹ️ La base de datos ya tiene {count} propiedades. Saltando seeding.")
            return

        logger.info("🏠 Creando propiedades de prueba en Sevilla...")
        
        properties_data = [
            {
                "title": "Ático de Lujo en Triana",
                "description": "Espectacular ático con vistas al Guadalquivir. Terraza de 40m2, reformado integralmente.",
                "price": 450000.0,
                "location": "Calle Betis, Sevilla",
                "surface_area": 120.0,
                "property_type": PropertyType.ATICO,
                "features": {
                    "bedrooms": 3, "bathrooms": 2, "has_terrace": True, "has_lift": True, 
                    "has_ac": True, "conservation_state": ConservationState.REFORMADO
                }
            },
            {
                "title": "Piso Familiar en Nervión",
                "description": "Gran piso cerca del estadio y centro comercial. Ideal familias. Garaje incluido.",
                "price": 320000.0,
                "location": "Avenida Eduardo Dato, Sevilla",
                "surface_area": 145.0,
                "property_type": PropertyType.PISO,
                "features": {
                    "bedrooms": 4, "bathrooms": 2, "has_lift": True, "has_heating": True,
                    "conservation_state": ConservationState.BUEN_ESTADO
                }
            },
            {
                "title": "Loft Industrial en Alameda",
                "description": "Espacio abierto diseño moderno en pleno centro. Techos altos.",
                "price": 210000.0,
                "location": "Alameda de Hércules, Sevilla",
                "surface_area": 85.0,
                "property_type": PropertyType.LOFT,
                "features": {
                    "bedrooms": 1, "bathrooms": 1, "has_ac": True, 
                    "conservation_state": ConservationState.REFORMADO
                }
            },
            {
                "title": "Casa Palacio en Santa Cruz",
                "description": "Casa histórica con patio andaluz. Oportunidad única para inversión turística.",
                "price": 850000.0,
                "location": "Barrio de Santa Cruz, Sevilla",
                "surface_area": 250.0,
                "property_type": PropertyType.CASA,
                "features": {
                    "bedrooms": 5, "bathrooms": 4, "has_garden": True, "construction_year": 1920,
                    "conservation_state": ConservationState.A_REFORMAR
                }
            },
             {
                "title": "Apartamento Económico Macarena",
                "description": "Ideal inversión alquiler. Zona con alta demanda.",
                "price": 115000.0,
                "location": "Ronda de Capuchinos, Sevilla",
                "surface_area": 60.0,
                "property_type": PropertyType.PISO,
                "features": {
                    "bedrooms": 2, "bathrooms": 1, "has_lift": False,
                    "conservation_state": ConservationState.BUEN_ESTADO
                }
            }
        ]

        for p_data in properties_data:
            features_data = p_data.pop("features")
            
            # Crear Property main
            prop = Property(
                **p_data,
                owner_id=owner.id,
                status=PropertyStatus.PUBLISHED,
                operation_type=OperationType.VENTA
            )
            db.add(prop)
            db.flush() # Para obtener ID
            
            # Crear Features
            feat = PropertyFeatures(
                property_id=prop.id,
                **features_data
            )
            db.add(feat)
            
            # Crear Legal default
            legal = PropertyLegal(
                property_id=prop.id,
                energy_certification=EnergyCertification.E,
                nota_simple_status=None
            )
            db.add(legal)
            
            # Crear Financial default
            fin = PropertyFinancial(
                property_id=prop.id,
                price_m2 = p_data["price"] / p_data["surface_area"]
            )
            db.add(fin)
            
            # Crear Environment default
            env = PropertyEnvironment(
                property_id=prop.id
            )
            db.add(env)
            
        db.commit()
        logger.info(f"✅ Se han insertado {len(properties_data)} propiedades exitosamente.")

    except Exception as e:
        logger.error(f"❌ Error durante el seeding: {e}", exc_info=True)
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_db()
