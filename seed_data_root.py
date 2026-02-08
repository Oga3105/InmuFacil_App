import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Setup path: Use standard project root (current directory)
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.append(current_dir)

# Imports using FULL package paths (as uvicorn does)
try:
    from backend.src.models.base import Base
    from backend.src.config.database import SessionLocal, engine
    
    from backend.src.models.users import User
    from backend.src.models.properties import Property, PropertyFeatures, PropertyLegal, PropertyFinancial, PropertyEnvironment
    from backend.src.models.enums import (
        PropertyStatus, PropertyType, OperationType, UserType, 
        Orientation, HeatingType, ConservationState, EnergyCertification
    )
    from backend.src.utils.security import get_password_hash
except ImportError as e:
    print(f"CRITICAL IMPORT ERROR: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Configuración de BD
# Usamos localhost para script local
SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/inmufacil_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def seed_db():
    db = SessionLocal()
    try:
        print("🌱 Iniciando Seeding de Datos (Desde Root)...")
        
        # 1. Crear Usuario Propietario
        owner = db.query(User).filter(User.email == "propietario@test.com").first()
        if not owner:
            print("👤 Creando usuario propietario...")
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
            print(f"✅ Usuario creado: ID {owner.id}")
        else:
            print(f"ℹ️ Usuario existente: ID {owner.id}")

        # 2. Verificar Propiedades
        count = db.query(Property).count()
        if count > 0:
            print(f"ℹ️ La base de datos ya tiene {count} propiedades. Saltando seeding.")
            return

        print("🏠 Creando propiedades de prueba en Sevilla...")
        
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
        print(f"✅ Se han insertado {len(properties_data)} propiedades exitosamente.")

    except Exception as e:
        print(f"❌ Error durante el seeding: {repr(e)}") # Use repr to avoid encoding errors
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_db()
