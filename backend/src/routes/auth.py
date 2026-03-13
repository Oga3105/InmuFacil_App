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
from jose import jwt, JWTError
import os

from backend.src.config.database import get_db
from backend.src.models import User, UserType, DNIStatus
from backend.src.utils.filters import validate_user_is_not_agency, log_blocked_attempt
from backend.src.utils.security import verify_password, get_password_hash, create_access_token
from backend.src.services.email_service import (
    generate_verification_token, get_token_expiration, 
    send_verification_email, verify_token
)
from backend.src.schemas.base import (
    UserCreate, UserResponse, Token, VerifyEmailRequest,
    PasswordResetRequest, PasswordResetConfirm, ChangePassword
)
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



def get_user_by_email(db: Session, email: str):
    """Get user by email"""
    return db.query(User).filter(User.email == email).first()

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """
    Validate Token and get current user.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = get_user_by_email(db, email=email)
    if user is None:
        raise credentials_exception
    return user


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
    
    # Step 4: Generate MFA Token
    verification_token = generate_verification_token()
    token_expires = get_token_expiration() # 15 min

    # Step 5: Create new user
    new_user = User(
        email=user_data.email,
        hashed_password=hashed_password,
        full_name=user_data.full_name,
        user_type=UserType(user_data.user_type),
        dni_status=DNIStatus.SIN_VERIFICAR,
        email_verified=False,
        verification_token=verification_token,
        token_expires_at=token_expires,
        dni_verified=False,
        failed_upload_attempts=0
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Step 6: Send Verification Email
    # In production use background task for this
    await send_verification_email(new_user.email, verification_token)
    
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


# ============================================================================
# MFA & Password Reset Endpoints
# ============================================================================

@router.post("/verify-email", 
            summary="Verify Email Address (MFA)",
            description="Verify user email with 6-digit MFA code")
async def verify_email(
    request: VerifyEmailRequest,
    db: Session = Depends(get_db)
):
    """
    Verify email with MFA token.
    @Shield: Constant-time comparison
    """
    user = get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(status_code=400, detail="User not found")
        
    if user.email_verified:
        return {"message": "Email already verified"}
        
    # Verify Token
    is_valid, error = verify_token(
        request.token, 
        user.verification_token, 
        user.token_expires_at
    )
    
    if not is_valid:
        raise HTTPException(status_code=400, detail=error)
        
    # Mark as verified
    user.email_verified = True
    user.verification_token = None
    user.token_expires_at = None
    db.commit()
    
    logger.info(f"[OK] Email verified for: {user.email}")
    return {"message": "Email verified successfully"}


@router.post("/request-password-reset", 
            summary="Request Password Reset",
            description="Send 6-digit code to email for password reset")
async def request_password_reset(
    request: PasswordResetRequest,
    db: Session = Depends(get_db)
):
    """
    Initiate password reset flow.
    """
    user = get_user_by_email(db, request.email)
    if not user:
        # Prevent user enumeration - return OK even if user not found
        # But for dev debug we might want to know.
        # Strict security: return OK.
        return {"message": "If email exists, code has been sent"}
        
    # Generate new token
    token = generate_verification_token()
    user.verification_token = token
    user.token_expires_at = get_token_expiration()
    db.commit()
    
    # Send Email
    await send_verification_email(user.email, token)
    
    logger.info(f"[AUTH] Password reset requested for: {user.email}")
    return {"message": "Verification code sent to email"}


@router.post("/reset-password", 
            summary="Confirm Password Reset",
            description="Reset password using 6-digit code")
async def reset_password(
    request: PasswordResetConfirm,
    db: Session = Depends(get_db)
):
    """
    Complete password reset.
    """
    user = get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(status_code=400, detail="Invalid request")
        
    # Verify Token
    is_valid, error = verify_token(
        request.token, 
        user.verification_token, 
        user.token_expires_at
    )
    
    if not is_valid:
        raise HTTPException(status_code=400, detail=error)
        
    # Update Password
    user.hashed_password = get_password_hash(request.new_password)
    user.verification_token = None
    user.token_expires_at = None
    db.commit()
    
    logger.info(f"[AUTH] Password reset successful for: {user.email}")
    return {"message": "Password reset successfully"}


# ============================================================================
# Change Password (Authenticated)
# ============================================================================

@router.post(
    "/change-password",
    summary="Change Password (Authenticated)",
    description="Change the current user's password by providing the current and new password.",
    tags=["Auth"]
)
async def change_password(
    payload: ChangePassword,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not verify_password(payload.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Contraseña actual incorrecta"
        )

    current_user.hashed_password = get_password_hash(payload.new_password)
    db.commit()

    logger.info(f"[AUTH] Password changed for: {current_user.email}")
    return {"message": "Contraseña actualizada"}
