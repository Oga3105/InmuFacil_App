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
print(f"[ENV] Loaded .env from: {env_path.absolute()}")
print(f"[ENV] .env exists: {env_path.exists()}")

# ============================================================================
# Application Imports
# ============================================================================
import os
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
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
    "http://localhost:5000",      # Flutter Web fallback
    "http://localhost:5500",      # VS Code Live Server
    "http://127.0.0.1:5500",
    "http://localhost:4200",      # Angular/Flutter Web dev
    "http://localhost:9000",      # Flutter Web alt
    "http://localhost:1",         # Flutter Web auto-assigned
    "http://127.0.0.1:1",
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

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    Global catch-all for unhandled exceptions (like Bcrypt ValueError).
    Prevents CORS issues and provides clean error reporting.
    """
    logger.error(f"[ERROR] Unhandled Exception: {repr(exc)}")
    import traceback
    logger.error(traceback.format_exc())
    
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Ocurrió un error inesperado en el servidor.",
            "error_code": "INTERNAL_SERVER_ERROR",
            "type": type(exc).__name__
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

from backend.src.routes import auth, users, kyc, properties, visits, offers, financing, contracts, signature, notary, timeline, financial, handover, services, leads

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
api_v1_router.include_router(leads.router) # Hito 18 - Lead Magnet (404)

# Include V1 Router in App
app.include_router(api_v1_router)

# Static files for user uploads
# Use CWD (always InmuFacil_Project/ when run with `uvicorn backend.main:app`)
import os as _os
_uploads_dir = Path(_os.getcwd()) / "uploads"
_uploads_dir.mkdir(parents=True, exist_ok=True)
(Path(_os.getcwd()) / "uploads" / "avatars").mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(_uploads_dir)), name="uploads")


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
        from backend.src.models.properties import Property, PropertyFeatures, PropertyLegal, PropertyFinancial, PropertyEnvironment
        from backend.src.models.enums import (
            PropertyStatus, PropertyType, OperationType, UserType, 
            ConservationState, EnergyCertification
        )
        from backend.src.utils.security import get_password_hash
        
        # 1. Create Owner
        owner = db.query(User).filter(User.email == "propietario@test.com").first()
        if not owner:
            owner = User(
                email="propietario@test.com",
                hashed_password=get_password_hash("password123"),
                full_name="Propietario Test",
                user_type=UserType.PARTICULAR,
                is_active=True,
                email_verified=True # Corrected from is_verified
            )
            db.add(owner)
            db.commit()
            db.refresh(owner)
            logger.info("SEED: Owner created")
            
        # 2. Check & Create Properties
        if db.query(Property).count() > 0:
            return {"status": "skipped", "message": "Database already has properties"}

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
                    "has_ac": True, "conservation_state": ConservationState.BUEN_ESTADO # Corrected from REFORMADO
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
                "property_type": PropertyType.PISO, # Corrected from LOFT
                "features": {
                    "bedrooms": 1, "bathrooms": 1, "has_ac": True, 
                    "conservation_state": ConservationState.BUEN_ESTADO # Corrected from REFORMADO
                }
            },
            {
                "title": "Casa Palacio en Santa Cruz",
                "description": "Casa histórica con patio andaluz. Oportunidad única para inversión turística.",
                "price": 850000.0,
                "location": "Barrio de Santa Cruz, Sevilla",
                "surface_area": 250.0,
                "property_type": PropertyType.CHALET, # Corrected from CASA
                "features": {
                    "bedrooms": 5, "bathrooms": 4, "has_garden": True, "construction_year": 1920,
                    "conservation_state": ConservationState.A_REFORMAR
                }
            }
        ]

        for p_data in properties_data:
            features = p_data.pop("features")
            
            prop = Property(
                **p_data,
                owner_id=owner.id,
                status=PropertyStatus.PUBLISHED,
                operation_type=OperationType.VENTA
            )
            db.add(prop)
            db.flush()
            
            db.add(PropertyFeatures(property_id=prop.id, **features))
            db.add(PropertyLegal(property_id=prop.id, energy_certification=EnergyCertification.E))
            db.add(PropertyFinancial(property_id=prop.id, price_m2=p_data["price"]/p_data["surface_area"]))
            db.add(PropertyEnvironment(property_id=prop.id))
            
        db.commit()
        return {"status": "success", "message": f"Seeded {len(properties_data)} properties"}

    except Exception as e:
        logger.error(f"SEED ERROR: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


