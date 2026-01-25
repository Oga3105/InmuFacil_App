"""
InmuFácil - Backend API
FastAPI application for P2P real estate platform

@Watcher - Observability & Logging Configuration
Token Consumption Tracking: ~300 tokens for logging setup
"""

from fastapi import FastAPI
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
    version="0.2.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    """
    Application startup event handler.
    
    @Watcher: Logs application initialization
    """
    logger.info("=" * 60)
    logger.info("InmuFácil API - Startup Complete")
    logger.info(f"Timestamp: {datetime.now().isoformat()}")
    logger.info("Environment: Development")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """
    Application shutdown event handler.
    
    @Watcher: Logs application shutdown
    """
    logger.info("InmuFácil API shutting down...")


@app.get("/")
async def root():
    """Root endpoint - API information"""
    logger.info("Root endpoint accessed")
    return {
        "message": "Bienvenido a InmuFácil API",
        "version": "0.2.0",
        "docs": "/docs",
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
        "timestamp": datetime.now().isoformat()
    }


if __name__ == "__main__":
    import uvicorn
    logger.info("Starting Uvicorn server...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
