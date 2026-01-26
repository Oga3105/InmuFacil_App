"""
Authentication Router

@Shield: Secure user registration and login
@Jules: JWT token generation and validation
@Architect: Integration with anti-agency filter

Endpoints:
- POST /auth/register - User registration with anti-agency validation
- POST /auth/token - Login and JWT token generation
"""

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import jwt
import os

from backend.database import get_db
from backend.models import User, UserType, DNIStatus
from backend.schemas import UserCreate, UserResponse, Token
from backend.core.security import get_password_hash, verify_password
from backend.filters import validate_user_is_not_agency, log_blocked_attempt
import logging

logger = logging.getLogger("inmufacil.auth")

# Create router
router = APIRouter()

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

# JWT Configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30


# ============================================================================
# Helper Functions
# ============================================================================

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    Create JWT access token.
    
    Args:
        data: Payload data to encode
        expires_delta: Token expiration time
        
    Returns:
        Encoded JWT token
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def get_user_by_email(db: Session, email: str):
    """Get user by email"""
    return db.query(User).filter(User.email == email).first()


# ============================================================================
# Registration Endpoint
# ============================================================================

@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register New User",
    description="""Register a new user with anti-agency validation.
    
    **Security Features:**
    - Email uniqueness validation
    - Password hashing (bcrypt)
    - Anti-agency filter (Escudo Anti-Inmo)
    - Audit logging
    
    **Process:**
    1. Validate user is not an agency
    2. Check email uniqueness
    3. Hash password
    4. Create user with 'pendiente' KYC status
    5. Return user data (no password)
    """,
    tags=["Auth"]
)
async def register(
    user_data: UserCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Register a new user.
    
    @Shield: Anti-agency validation and password hashing
    @Watcher: Audit logging
    """
    logger.info(f"[AUTH] Registration attempt for email: {user_data.email}")
    
    # Step 1: Anti-agency validation
    is_valid, reason = await validate_user_is_not_agency(
        email=user_data.email,
        full_name=user_data.full_name,
        user_type=user_data.user_type
    )
    
    if not is_valid:
        # Log blocked attempt
        client_ip = request.client.host if request.client else "unknown"
        log_blocked_attempt(
            email=user_data.email,
            full_name=user_data.full_name,
            reason=reason,
            ip_address=client_ip,
            country="ES"
        )
        logger.warning(f"[SHIELD] Registration blocked: {reason} | Email: {user_data.email}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Registration not allowed: {reason}"
        )
    
    # Step 2: Check if email already exists
    existing_user = get_user_by_email(db, user_data.email)
    if existing_user:
        logger.warning(f"[AUTH] Registration failed: Email already exists: {user_data.email}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Step 3: Hash password
    hashed_password = get_password_hash(user_data.password)
    
    # Step 4: Create new user
    new_user = User(
        email=user_data.email,
        hashed_password=hashed_password,
        full_name=user_data.full_name,
        user_type=UserType(user_data.user_type),
        dni_status=DNIStatus.PENDIENTE,
        email_verified=False,
        dni_verified=False,
        failed_upload_attempts=0
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    logger.info(f"[OK] User registered successfully: {new_user.email} (ID: {new_user.id})")
    
    return new_user


# ============================================================================
# Login Endpoint
# ============================================================================

@router.post(
    "/token",
    response_model=Token,
    summary="Login (Get Access Token)",
    description="""Authenticate user and return JWT access token.
    
    **OAuth2 Password Flow:**
    - Uses standard OAuth2 password grant
    - Returns JWT access token
    - Token expires in 30 minutes
    
    **Usage:**
    ```
    POST /auth/token
    Content-Type: application/x-www-form-urlencoded
    
    username=user@example.com&password=SecurePass123
    ```
    """,
    tags=["Auth"]
)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """
    Authenticate user and return JWT token.
    
    @Shield: Password verification
    @Jules: JWT token generation
    """
    logger.info(f"[AUTH] Login attempt for: {form_data.username}")
    
    # Step 1: Get user by email (username field contains email)
    user = get_user_by_email(db, form_data.username)
    
    if not user:
        logger.warning(f"[AUTH] Login failed: User not found: {form_data.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Step 2: Verify password
    if not verify_password(form_data.password, user.hashed_password):
        logger.warning(f"[AUTH] Login failed: Invalid password for: {form_data.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Step 3: Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email, "user_id": user.id},
        expires_delta=access_token_expires
    )
    
    logger.info(f"[OK] Login successful: {user.email} (ID: {user.id})")
    
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }
