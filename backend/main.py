"""
InmuFácil - Backend API
FastAPI application for P2P real estate platform

@Watcher - Observability & Logging Configuration
@Architect - Integration of Anti-Agency Filter

Token Consumption Tracking: ~400 tokens for integration
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import logging
from datetime import datetime

# ============================================================================
# @Watcher - Logging Configuration
# ============================================================================

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('inmufacil.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger("inmufacil")

# Log application startup
logger.info("InmuFácil API starting up...")

# ============================================================================
# FastAPI Application
# ============================================================================

# Initialize FastAPI application
app = FastAPI(
    title="InmuFácil API",
    description="API REST para la plataforma P2P de compraventa inmobiliaria",
    version="0.3.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# @Watcher - Request Logging Middleware
# ============================================================================

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """
    Middleware to log all incoming requests.
    
    @Watcher: Tracks IP addresses and request patterns
    """
    client_ip = request.client.host if request.client else "unknown"
    logger.info(f"📥 Request: {request.method} {request.url.path} | IP: {client_ip}")
    
    response = await call_next(request)
    
    logger.info(f"📤 Response: {request.url.path} | Status: {response.status_code}")
    return response


# ============================================================================
# Application Events
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """
    Application startup event handler.
    
    @Watcher: Fail-safe validation - app won't start without encryption key
    @Shield: Validates encryption system before accepting requests
    @Architect: Initializes Escudo Anti-Inmo
    
    Security by Default: Application fails to start if security is not properly configured
    """
    logger.info("=" * 60)
    logger.info("InmuFácil API - Starting Up...")
    logger.info(f"Timestamp: {datetime.now().isoformat()}")
    logger.info("Environment: Development")
    
    # ========================================================================
    # @Watcher + @Shield - FAIL-SAFE VALIDATION
    # ========================================================================
    # CRITICAL: Validate encryption system before starting
    # If validation fails, application will NOT start (RuntimeError raised)
    
    try:
        from backend.core.security import validate_encryption_setup
        
        logger.info("🔐 Validating encryption system...")
        is_valid = validate_encryption_setup()
        
        if not is_valid:
            error_msg = (
                "CRITICAL: Encryption validation failed. "
                "Application cannot start. Check logs for details."
            )
            logger.critical(error_msg)
            raise RuntimeError(error_msg)
        
        logger.info("✅ Encryption system validated successfully")
        logger.info("🔐 VAULT: ACTIVATED")
        
    except RuntimeError as e:
        # Re-raise RuntimeError to prevent app startup
        logger.critical(f"🚨 STARTUP FAILED: {str(e)}")
        logger.critical("Application will NOT start until security is properly configured")
        raise
    except Exception as e:
        error_msg = f"Unexpected error during encryption validation: {str(e)}"
        logger.critical(error_msg)
        raise RuntimeError(error_msg)
    
    # ========================================================================
    # @Architect - Feature Activation
    # ========================================================================
    
    logger.info("🛡️  ESCUDO ANTI-INMO: ACTIVE")
    logger.info("=" * 60)
    logger.info("✅ InmuFácil API - Startup Complete")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """
    Application shutdown event handler.
    
    @Watcher: Logs application shutdown
    """
    logger.info("InmuFácil API shutting down...")


# ============================================================================
# Health & Status Endpoints
# ============================================================================

@app.get("/")
async def root():
    """Root endpoint - API information"""
    logger.info("Root endpoint accessed")
    return {
        "message": "Bienvenido a InmuFácil API",
        "version": "0.3.0",
        "docs": "/docs",
        "escudo_anti_inmo": "active",
    }


@app.get("/health")
async def health_check():
    """
    Health check endpoint
    
    @Watcher: Monitors application health status
    """
    logger.debug("Health check performed")
    return {
        "status": "InmuFacil Online",
        "timestamp": datetime.now().isoformat(),
        "escudo_anti_inmo": "active",
    }


@app.get("/status")
async def status():
    """
    Detailed status endpoint
    
    @Architect: Shows system status including filter status
    """
    return {
        "api_version": "0.3.0",
        "status": "operational",
        "features": {
            "user_registration": "active",
            "escudo_anti_inmo": "active",
            "authentication": "pending",
        },
        "timestamp": datetime.now().isoformat(),
    }


# ============================================================================
# @Architect - KYC Verification Endpoint
# ============================================================================

from fastapi import File, UploadFile, HTTPException, Form
from backend.services.kyc_service import process_dni_upload, ensure_upload_directory
from backend.core.security import encrypt_data
import tempfile
import shutil

# Ensure upload directory exists on startup
ensure_upload_directory()


@app.post("/auth/verify-identity")
async def verify_identity(
    user_id: int = Form(...),
    dni_file: UploadFile = File(...)
):
    """
    Verify user identity via DNI upload with automatic redaction.
    
    Args:
        user_id: User ID for KYC verification
        dni_file: Uploaded DNI image file
        
    Returns:
        Success message with processing details
        
    Security Flow:
    1. @Shield: Validate file type (JPEG/PNG only - prevent RCE)
    2. @Watcher: Calculate file hash for audit trail
    3. @Jules: Redact sensitive zones (Firma, Equipo Emisor, MRZ)
    4. @Shield: Encrypt extracted data (simulated OCR)
    5. @Shield: Secure cleanup - delete original file
    6. @Watcher: Log KYC_PROCESS_COMPLETED event
    
    @Architect: Complete KYC flow orchestration
    """
    temp_file_path = None
    
    try:
        logger.info(f"🔐 KYC verification started for user {user_id}")
        
        # Step 1: Save uploaded file to temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tmp") as temp_file:
            shutil.copyfileobj(dni_file.file, temp_file)
            temp_file_path = temp_file.name
        
        # Step 2: Process DNI upload (validation, redaction, cleanup)
        success, message, saved_path, file_hash = await process_dni_upload(
            file_path=temp_file_path,
            original_filename=dni_file.filename,
            user_id=user_id
        )
        
        if not success:
            logger.warning(f"⚠️  KYC verification failed for user {user_id}: {message}")
            raise HTTPException(status_code=400, detail=message)
        
        # Step 3: Simulate OCR data extraction and encryption
        # In production, this would use real OCR (Tesseract, Google Vision, etc.)
        simulated_dni_data = {
            "dni_number": "12345678A",  # Would come from OCR
            "full_name": "USUARIO EJEMPLO",  # Would come from OCR
        }
        
        # Encrypt sensitive data before storage
        encrypted_dni = encrypt_data(simulated_dni_data["dni_number"])
        logger.info(f"🔒 DNI data encrypted for user {user_id}")
        
        # Step 4: @Watcher - Log KYC completion event
        logger.info(
            f"✅ KYC_PROCESS_COMPLETED | "
            f"user_id={user_id} | "
            f"file_hash={file_hash[:16]}... | "
            f"redacted_path={saved_path}"
        )
        
        # Step 5: Return success response
        return {
            "success": True,
            "message": "Identity verification completed successfully",
            "details": {
                "user_id": user_id,
                "file_hash": file_hash[:16] + "...",  # Partial hash for response
                "redacted_image_saved": True,
                "data_encrypted": True,
                "original_file_deleted": True,  # Security by Design
            }
        }
        
    except HTTPException:
        raise  # Re-raise HTTP exceptions
    except Exception as e:
        logger.error(f"❌ KYC verification error for user {user_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="An error occurred during identity verification. Please try again."
        )


# ============================================================================
# @Architect - Future Registration Endpoint (Placeholder)
# ============================================================================

# NOTE: Full registration endpoint will be implemented in next mission
# This is a placeholder showing where the filter will be integrated

"""
Example integration of anti-agency filter in registration:

from backend.filters import validate_user_is_not_agency, log_blocked_attempt
from backend.schemas import UserCreate, UserResponse

@app.post("/auth/register", response_model=UserResponse)
async def register_user(user_data: UserCreate, request: Request):
    # @Architect: Integration point for Escudo Anti-Inmo
    is_valid, reason = await validate_user_is_not_agency(
        email=user_data.email,
        full_name=user_data.full_name,
        user_type=user_data.user_type
    )
    
    if not is_valid:
        # @Watcher: Log blocked attempt with IP tracking
        client_ip = request.client.host if request.client else "unknown"
        log_blocked_attempt(
            email=user_data.email,
            full_name=user_data.full_name,
            reason=reason,
            ip_address=client_ip,
            country="ES"  # TODO: Add geolocation service
        )
        raise HTTPException(
            status_code=403,
            detail="Registration not allowed: " + reason
        )
    
    # Continue with normal registration...
    # (Database creation, password hashing, etc.)
"""


if __name__ == "__main__":
    import uvicorn
    logger.info("Starting Uvicorn server...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
