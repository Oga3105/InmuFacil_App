import sys
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add the project root directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

# CORRECT IMPORTS (backend.src...) matching the running app
from backend.src.config.database import SessionLocal
from backend.src.models.users import User
from backend.src.models.properties import Property, PropertyFeatures, PropertyLegal, PropertyFinancial, PropertyEnvironment, PropertyMedia
from backend.src.models.enums import PropertyStatus, PropertyType, OperationType, UserType, DNIStatus, MediaType, ConservationState, EnergyCertification
from backend.src.utils.security import get_password_hash

def seed_sevilla_data():
    db = SessionLocal()
    try:
        # 1. Create User
        user_email = "test_sevilla@inmufacil.com"
        user = db.query(User).filter(User.email == user_email).first()
        
        if not user:
            logger.info(f"Creating user: {user_email}")
            user = User(
                email=user_email,
                hashed_password=get_password_hash("password123"),
                full_name="Inmobiliaria Hispalense (Test)",
                dni_status=DNIStatus.VALIDADO,
                user_type=UserType.PROFESIONAL,
                email_verified=True,
                is_active=True
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            logger.info(f"User already exists: {user_email}")

        # 2. Create Properties
        properties_data = [
            {
                "title": "Ático con vistas a la Giralda",
                "description": "Espectacular ático en el corazón de Sevilla con vistas directas a la Giralda. Terraza privada de 50m2.",
                "price": 450000.0,
                "location": "37.3862, -5.9925",
                "surface_area": 120.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 3, "bathrooms": 2, "has_terrace": True, "has_lift": True, "has_ac": True}
            },
            {
                "title": "Apartamento histórico reformado",
                "description": "En pleno Barrio de Santa Cruz. Edificio del siglo XVIII rehabilitado. Techos altos y patio andaluz.",
                "price": 280000.0,
                "location": "37.3870, -5.9918",
                "surface_area": 85.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 2, "bathrooms": 1, "has_ac": True, "conservation_state": ConservationState.BUEN_ESTADO}
            },
            {
                "title": "Piso luminoso en Calle Betis",
                "description": "Vistas al río Guadalquivir y la Torre del Oro. Primera línea en Triana.",
                "price": 320000.0,
                "location": "37.3845, -6.0030",
                "surface_area": 95.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 3, "bathrooms": 2, "has_lift": True}
            },
            {
                "title": "Gran piso cerca del estadio",
                "description": "Zona Nervión. Ideal familias. Cerca de colegios y centro comercial.",
                "price": 380000.0,
                "location": "37.3825, -5.9750",
                "surface_area": 140.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 4, "bathrooms": 2, "has_lift": True, "has_heating": True}
            },
            {
                "title": "Loft bohemio en Alameda de Hércules",
                "description": "Espacio diáfano en la zona más moderna de Sevilla. Ideal para artistas.",
                "price": 210000.0,
                "location": "37.3995, -5.9940",
                "surface_area": 70.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 1, "bathrooms": 1, "has_ac": True}
            },
            {
                "title": "Piso familiar cerca de la Feria",
                "description": "Los Remedios. Amplio y cercano al recinto ferial. Garaje incluido.",
                "price": 295000.0,
                "location": "37.3760, -5.9990",
                "surface_area": 110.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 3, "bathrooms": 2, "has_lift": True}
            },
            {
                "title": "Ideal inversores frente estación",
                "description": "Santa Justa. Alta rentabilidad por alquiler. Muy bien comunicado.",
                "price": 185000.0,
                "location": "37.3920, -5.9760",
                "surface_area": 65.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 2, "bathrooms": 1}
            },
            {
                "title": "Bajo con patio junto a muralla",
                "description": "Macarena. Bajo con encanto y patio privado de 20m2.",
                "price": 150000.0,
                "location": "37.4030, -5.9890",
                "surface_area": 60.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 2, "bathrooms": 1, "has_garden": True}
            },
            {
                "title": "Chalet exclusivo junto al Parque",
                "description": "El Porvenir. Villa independiente con piscina y jardín de 500m2. Lujo.",
                "price": 850000.0,
                "location": "37.3710, -5.9810",
                "surface_area": 350.0,
                "property_type": PropertyType.CHALET,
                "features": {"bedrooms": 5, "bathrooms": 4, "has_pool": True, "has_garden": True, "has_ac": True}
            },
            {
                "title": "Oficina/Estudio moderno",
                "description": "Isla de la Cartuja. Espacio profesional adaptable a vivienda (loft).",
                "price": 190000.0,
                "location": "37.4050, -6.0050",
                "surface_area": 80.0,
                "property_type": PropertyType.OFICINA,
                "features": {"bedrooms": 0, "bathrooms": 1, "has_ac": True}
            }
        ]

        count = 0
        for p_data in properties_data:
            exists = db.query(Property).filter(Property.location == p_data["location"]).first()
            if not exists:
                features_data = p_data.pop("features")
                image_url = "https://placehold.co/600x400"

                prop = Property(
                    **p_data,
                    owner_id=user.id,
                    status=PropertyStatus.PUBLISHED,
                    operation_type=OperationType.VENTA
                )
                db.add(prop)
                db.flush()
                
                db.add(PropertyFeatures(property_id=prop.id, **features_data))
                
                # Create Media
                db.add(PropertyMedia(
                    property_id=prop.id, 
                    media_type=MediaType.IMAGE,
                    file_path=image_url,
                    is_main=True
                ))
                
                # Other satellites
                db.add(PropertyLegal(property_id=prop.id, energy_certification=EnergyCertification.EN_TRAMITE))
                db.add(PropertyFinancial(property_id=prop.id, price_m2=p_data["price"]/p_data["surface_area"]))
                db.add(PropertyEnvironment(property_id=prop.id))
                
                count += 1
            else:
                logger.info(f"Property at {p_data['location']} already exists.")
        
        db.commit()
        logger.info(f"Seeding complete. Inserted {count} properties.")

    except Exception as e:
        logger.error(f"Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_sevilla_data()
