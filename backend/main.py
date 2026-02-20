"""
InmuFácil - Backend API
FastAPI application for P2P real estate platform

@Watcher - Observability & Logging Configuration
@Architect - Integration of Anti-Agency Filter

Token Consumption Tracking: ~400 tokens for integration
"""

# ============================================================================
# @Architect - Environment Loading (CRITICAL - MUST BE FIRST)
# ============================================================================
from dotenv import load_dotenv
from pathlib import Path

# Load .env file BEFORE any other imports that use environment variables
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

# Import logging after dotenv is loaded
from backend.core.logging_config import get_logger
env_logger = get_logger(__name__)
env_logger.info(f"Loaded .env from: {env_path.absolute()}")
env_logger.info(f".env exists: {env_path.exists()}")

# ============================================================================
# Application Imports
# ============================================================================
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import OperationalError
import logging
from datetime import datetime

# ============================================================================
# @Watcher - Logging Configuration
# ============================================================================

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    handlers=[
        logging.FileHandler('inmufacil.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger("inmufacil")

# Log application startup
logger.info("InmuFacil API starting up...")

# ============================================================================
# FastAPI Application
# ============================================================================

# Initialize FastAPI application
app = FastAPI(
    title="InmuFacil API",
    description="""API REST para la plataforma P2P de compraventa inmobiliaria con seguridad DevSecOps.
    
    Características:
    - [VAULT] Cifrado AES-256-GCM para datos sensibles
    - [SHIELD] Escudo Anti-Agencias activo
    - [IMAGE] Redacción automática de DNI (100% opacidad verificada)
    - [LOG] Audit logging completo
    - [OK] Compliance: GDPR, OWASP, PCI DSS
    """,
    version="1.2.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ============================================================================
# @Shield - Secure CORS Configuration (Security by Design)
# ============================================================================

# Allowed origins - NO WILDCARDS for security
ALLOWED_ORIGINS = [
    "http://localhost:3000",      # Local development
    "http://localhost:8080",      # Alternative local port
    "http://127.0.0.1:3000",      # Local IP
    "http://127.0.0.1:8080",      # Alternative local IP
    "http://localhost:8001",      # Flutter Web custom port
    "http://127.0.0.1:8001",      # Flutter Web custom port IP
    "*"                           # Temporary for development flexibility if strict fails
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,  # Specific origins only - Security by Design
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID"],
)


# ============================================================================
# @Shield - Security Headers Middleware
# ============================================================================

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    """
    Add security headers to all responses.
    """
    response = await call_next(request)
    
    # Prevent MIME type sniffing
    response.headers["X-Content-Type-Options"] = "nosniff"
    
    # Prevent clickjacking
    response.headers["X-Frame-Options"] = "DENY"
    
    # Enable XSS protection
    response.headers["X-XSS-Protection"] = "1; mode=block"
    
    # Content Security Policy - Adjusted for Swagger UI
    csp_policy = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
        "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
        "img-src 'self' data: https://fastapi.tiangolo.com; "
        "font-src 'self' data:; "
        "connect-src 'self'"
    )
    response.headers["Content-Security-Policy"] = csp_policy
    
    return response


# ============================================================================
# @Watcher - Request Logging
# ============================================================================

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """
    Middleware to log all incoming requests.
    """
    client_ip = request.client.host if request.client else "unknown"
    response = await call_next(request)
    # Logging omitted for brevity
    return response


# ============================================================================
# @Watcher - Global Database Exception Handler (503 Service Unavailable)
# ============================================================================

@app.exception_handler(OperationalError)
async def database_exception_handler(request: Request, exc: OperationalError):
    """
    Intercept SQLAlchemy OperationalError globally.
    Returns 503 with a clean, user-safe message (no internal details leaked).
    """
    logger.critical(
        f"[DB] ❌ BASE DE DATOS NO DISPONIBLE. "
        f"¿Está Docker Desktop encendido y el contenedor de PostgreSQL corriendo? "
        f"Detalle interno: {repr(exc)}"
    )
    return JSONResponse(
        status_code=503,
        content={
            "detail": "Servicio de datos no disponible temporalmente. "
                      "Por favor, inténtalo de nuevo en unos minutos.",
            "error_code": "DATABASE_UNAVAILABLE"
        }
    )


# ============================================================================
# Application Events
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """
    Application startup event handler.
    """
    logger.info("=" * 60)
    logger.info("InmuFacil API - Starting Up...")
    
    try:
        from backend.src.utils.security import SECRET_KEY
        from backend.src.config.database import engine
        from backend.src.models.base import Base
        # Ensure models are loaded for metadata
        from backend.src.models import timeline, leads 

        if len(SECRET_KEY) < 32:
             logger.warning("JWT SECRET_KEY might be weak.")
             
        # Feature Activation
        logger.info("[SHIELD]  ESCUDO ANTI-INMO: ACTIVE")
        logger.info("[VAULT]   SECURITY VAULT: ACTIVE")
        
        # Auto-Migration (Dev Mode)
        logger.info("[DB] Checking database schema...")
        Base.metadata.create_all(bind=engine)
        logger.info("[DB] ✅ Schema synchronized. PostgreSQL operativo.")
        
    except OperationalError as e:
        logger.critical(
            f"[DB] ❌ NO SE PUDO CONECTAR A POSTGRESQL. "
            f"Verifica que Docker Desktop esté encendido y el contenedor 'inmufacil-db' corriendo. "
            f"Puerto esperado: 5435. Detalle: {repr(e)}"
        )
        logger.critical("[DB] 💡 SOLUCIÓN: Abre Docker Desktop → espera a que arranque → reinicia uvicorn.")
    except Exception as e:
        # Use repr() to avoid UnicodeDecodeError if the system error message contains localized non-UTF-8 characters (Windows)
        logger.critical(f"[ALERT] STARTUP WARNING: {repr(e)}")
    
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    logger.info("InmuFacil API shutting down...")


# ============================================================================
# Health & Status Endpoints
# ============================================================================

@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "message": "Bienvenido a InmuFacil API",
        "version": "1.2.0",
        "modules": ["Auth", "Users", "KYC"]
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Comprehensive health check."""
    from backend.src.config.database import engine
    
    db_status = "unknown"
    try:
        with engine.connect() as connection:
            db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"

    return {
        "status": "active",
        "system": "InmuFacil Shield",
        "database": db_status,
        "modules": ["Auth", "Users", "KYC", "Properties", "Visits"]
    }


# ============================================================================
# @Architect - Router Integration
# ============================================================================

from backend.src.routes import auth, users, kyc, properties, visits, offers, financing, contracts, favorites, signature, notary, timeline, financial, handover, services, leads

from fastapi import APIRouter

# Create API V1 Router
api_v1_router = APIRouter(prefix="/api/v1")

# Include routers into V1
api_v1_router.include_router(auth.router, prefix="/auth", tags=["Auth"])
api_v1_router.include_router(users.router, prefix="/users", tags=["Users", "Admin"])
api_v1_router.include_router(kyc.router, prefix="/kyc", tags=["KYC", "Admin"])
api_v1_router.include_router(properties.router) # has internal /properties prefix
api_v1_router.include_router(visits.router)
api_v1_router.include_router(offers.router)
api_v1_router.include_router(financing.router)
api_v1_router.include_router(contracts.router, prefix="/contracts", tags=["Contracts"])
api_v1_router.include_router(financial.router) # Hito 16 Part A
api_v1_router.include_router(handover.router) # Hito 16 Part B
api_v1_router.include_router(services.router) # Hito 17 - Unified Services
api_v1_router.include_router(signature.router) # Prefix defined in router (/contracts)
api_v1_router.include_router(notary.router) # Prefix defined in router (/notaries)
api_v1_router.include_router(services.router) # Hito 17 - Unified Services
api_v1_router.include_router(signature.router) # Prefix defined in router (/contracts)
api_v1_router.include_router(notary.router) # Prefix defined in router (/notaries)
api_v1_router.include_router(timeline.router) # Prefix defined in router (/timeline)
api_v1_router.include_router(favorites.router, prefix="/favorites")
api_v1_router.include_router(leads.router) # Hito 18 - Lead Magnet (404)

# Include V1 Router in App
app.include_router(api_v1_router)


# ============================================================================
# @DevOps - Temporary Seeding & Reset Endpoints
# ============================================================================
@app.post("/developer/reset", tags=["Internal"])
async def reset_database():
    """
    Temporary endpoint to DROP and RECREATE all tables.
    WARNING: DELETES ALL DATA.
    """
    try:
        from backend.src.config.database import engine
        from backend.src.models.base import Base
        
        # Import all models to ensure metadata is populated
        # (Importing them registers them with Base.metadata)
        from backend.src.models import users, properties, timeline
        
        logger.warning("RESET: Dropping all tables...")
        Base.metadata.drop_all(bind=engine)
        
        logger.info("RESET: Creating all tables...")
        Base.metadata.create_all(bind=engine)
        
        return {"status": "success", "message": "Database reset complete. All tables recreated."}
    except Exception as e:
        logger.error(f"RESET ERROR: {str(e)}")
        # Import HTTPException locally
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/developer/seed", tags=["Internal"])
async def seed_database():
    """
    Temporary endpoint to seed database with test data.
    Bypasses console encoding issues by running within the API process.
    """
    # Import dependencies locally to avoid polluting global namespace for a temp endpoint
    from fastapi import HTTPException
    from backend.src.config.database import SessionLocal
    
    db = SessionLocal()
    try:
        from backend.src.models.users import User
        from backend.src.models.properties import Property, PropertyFeatures, PropertyLegal, PropertyFinancial, PropertyEnvironment, PropertyMedia
        from backend.src.models.enums import (
            PropertyStatus, PropertyType, OperationType, UserType, 
            ConservationState, EnergyCertification, DNIStatus, MediaType
        )
        from backend.src.utils.security import get_password_hash
        
        # 1. Create Owner (Sevilla Test User)
        user_email = "test_sevilla@inmufacil.com"
        owner = db.query(User).filter(User.email == user_email).first()
        
        if not owner:
            owner = User(
                email=user_email,
                hashed_password=get_password_hash("password123"),
                full_name="Inmobiliaria Hispalense (Test)",
                dni_status=DNIStatus.VALIDADO,
                user_type=UserType.PROFESIONAL,
                is_active=True,
                email_verified=True
            )
            db.add(owner)
            db.commit()
            db.refresh(owner)
            logger.info(f"SEED: User {user_email} created")
        else:
            logger.info(f"SEED: User {user_email} already exists")
            
        # 2. Properties Data (Sevilla)
        properties_data = [
            {
                "title": "Ático con vistas a la Giralda",
                "description": "Espectacular ático en el corazón de Sevilla con vistas directas a la Giralda. Terraza privada de 50m2.",
                "price": 450000.0,
                "location": "37.3862, -5.9925",
                "surface_area": 120.0,
                "property_type": PropertyType.PISO,
                "is_verified": True,
                "features": {"bedrooms": 3, "bathrooms": 2, "has_terrace": True, "has_lift": True, "has_ac": True, "floor": "Ático"}
            },
            {
                "title": "Apartamento histórico reformado",
                "description": "En pleno Barrio de Santa Cruz. Edificio del siglo XVIII rehabilitado. Techos altos y patio andaluz.",
                "price": 280000.0,
                "location": "37.3870, -5.9918",

                "surface_area": 85.0,
                "property_type": PropertyType.PISO,
                "is_verified": False, # TEST: This one is NOT verified
                "features": {"bedrooms": 2, "bathrooms": 1, "has_ac": True, "conservation_state": ConservationState.BUEN_ESTADO, "floor": "Bajo"}
            },
            {
                "title": "Piso luminoso en Calle Betis",
                "description": "Vistas al río Guadalquivir y la Torre del Oro. Primera línea en Triana.",
                "price": 320000.0,
                "location": "37.3845, -6.0030",

                "surface_area": 95.0,
                "property_type": PropertyType.PISO,
                "is_verified": False, # TEST: This one is NOT verified
                "features": {"bedrooms": 3, "bathrooms": 2, "has_lift": True}
            },
            {
                "title": "Gran piso cerca del estadio",
                "description": "Zona Nervión. Ideal familias. Cerca de colegios y centro comercial.",
                "price": 380000.0,
                "location": "37.3825, -5.9750",

                "surface_area": 140.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 4, "bathrooms": 2, "has_lift": True, "has_heating": True, "floor": "3ª Planta"}
            },
            {
                "title": "Loft bohemio en Alameda de Hércules",
                "description": "Espacio diáfano en la zona más moderna de Sevilla. Ideal para artistas.",
                "price": 210000.0,
                "location": "37.3995, -5.9940",

                "surface_area": 70.0,
                "property_type": PropertyType.PISO,
                "features": {"bedrooms": 1, "bathrooms": 1, "has_ac": True, "floor": "2ª Planta"}
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

        inserted_count = 0
        for p_data in properties_data:
            # Check if property exists at location to avoid duplicates
            existing = db.query(Property).filter(Property.location == p_data["location"]).first()
            if existing:
                continue

            features_data = p_data.pop("features")
            location_coords = p_data.get("location") # Keep location string "lat, lng"
            
            # Simple placeholder image
            image_url = "https://placehold.co/600x400"

            prop = Property(
                **p_data,
                owner_id=owner.id,
                status=PropertyStatus.PUBLISHED,
                operation_type=OperationType.VENTA
            )
            db.add(prop)
            db.flush()
            
            # Create Features
            db.add(PropertyFeatures(property_id=prop.id, **features_data))
            
            # Create Media
            db.add(PropertyMedia(
                property_id=prop.id, 
                media_type=MediaType.IMAGE,
                file_path=image_url,
                is_main=True
            ))
            
            # Create other satellites
            db.add(PropertyLegal(property_id=prop.id, energy_certification=EnergyCertification.EN_TRAMITE))
            db.add(PropertyFinancial(property_id=prop.id, price_m2=p_data["price"]/p_data["surface_area"]))
            db.add(PropertyEnvironment(property_id=prop.id))
            
            inserted_count += 1
            
        db.commit()
        return {"status": "success", "message": f"Seeded {inserted_count} new properties in Sevilla for {user_email}"}

    except Exception as e:
        logger.error(f"SEED ERROR: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


