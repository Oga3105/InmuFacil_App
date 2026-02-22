import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Add the project root directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.core.logging_config import get_logger
logger = get_logger(__name__)

# Import using full package paths
from backend.src.models.base import Base
from backend.src.config.database import SessionLocal
# from backend.src.config.database import get_db # not needed for script
from backend.src.models.users import User
from backend.src.models.properties import Property, PropertyFeatures, PropertyLegal, PropertyFinancial, PropertyEnvironment
from backend.src.models.enums import (
    PropertyStatus, PropertyType, OperationType, UserType, 
    Orientation, HeatingType, ConservationState, EnergyCertification
)
from backend.src.utils.security import get_password_hash

# Configuración de BD directa para el script
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/inmufacil_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def seed_db():
    db = SessionLocal()
    try:
        logger.info("🌱 Iniciando Seeding de Datos...")
        
        # 1. Crear Usuario Propietario (si no existe)
        owner_email = "propietario@test.com"
        owner = db.query(User).filter(User.email == owner_email).first()
        if not owner:
            logger.info(f"👤 Creando usuario propietario: {owner_email}")
            owner = User(
                email=owner_email,
                hashed_password=get_password_hash("password123"),
                full_name="Propietario Test",
                phone="+34600123456",
                user_type=UserType.PARTICULAR, 
                is_active=True,
                email_verified=True
            )
            db.add(owner)
            db.commit()
            db.refresh(owner)
            logger.info(f"✅ Usuario creado: ID {owner.id}")
        else:
            logger.info(f"ℹ️ Usuario existente: ID {owner.id}")

        # 2. Propiedades data
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
                    "has_ac": True, "conservation_state": ConservationState.REFORMADO,
                    "floor": "Ático"
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
                    "conservation_state": ConservationState.BUEN_ESTADO,
                    "floor": "3ª Planta"
                }
            },
            {
                "title": "Loft Industrial en Alameda",
                "description": "Espacio abierto diseño moderno en pleno centro. Techos altos.",
                "price": 210000.0,
                "location": "Alameda de Hércules, Sevilla",
                "surface_area": 85.0,
                "property_type": PropertyType.PISO, 
                "features": {
                    "bedrooms": 1, "bathrooms": 1, "has_ac": True, 
                    "conservation_state": ConservationState.REFORMADO,
                    "floor": "Bajo"
                }
            }
        ]

        for p_data in properties_data:
            features_data = p_data.pop("features")
            
            # Find existing property
            existing_prop = db.query(Property).filter(Property.title == p_data["title"]).first()
            
            if existing_prop:
                logger.info(f"🔄 Actualizando propiedad: {p_data['title']}")
                # Update features
                if existing_prop.features:
                    for k, v in features_data.items():
                        setattr(existing_prop.features, k, v)
                else:
                    feat = PropertyFeatures(property_id=existing_prop.id, **features_data)
                    db.add(feat)
                continue

            # Create new
            prop = Property(
                **p_data,
                owner_id=owner.id,
                status=PropertyStatus.PUBLISHED,
                operation_type=OperationType.VENTA
            )
            db.add(prop)
            db.flush()
            
            feat = PropertyFeatures(property_id=prop.id, **features_data)
            db.add(feat)
            db.add(PropertyLegal(property_id=prop.id))
            db.add(PropertyFinancial(property_id=prop.id, price_m2=p_data["price"]/p_data["surface_area"]))
            db.add(PropertyEnvironment(property_id=prop.id))
            
        db.commit()
        logger.info("✅ Seeding completado exitosamente.")

    except Exception as e:
        logger.error(f"❌ Error durante el seeding: {repr(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_db()
