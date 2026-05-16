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
import firebase_admin
from firebase_admin import credentials, auth as firebase_auth_sdk

from backend.src.config.database import get_db
from backend.src.models import User, UserType, DNIStatus
from backend.src.utils.filters import validate_user_is_not_agency, log_blocked_attempt
from backend.src.services.moderation_alerts import send_blocked_registration_alert
from backend.src.utils.security import (
    verify_password, get_password_hash, create_access_token,
    get_current_active_user,
)
from backend.src.services.email_service import (
    generate_verification_token, get_token_expiration,
    send_verification_email, send_password_reset_email, verify_token
)
from backend.src.schemas.base import (
    UserCreate, UserResponse, Token, VerifyEmailRequest,
    PasswordResetRequest, PasswordResetConfirm, ChangePassword,
    GoogleAuthRequest, GoogleAuthResponse
)
import logging

logger = logging.getLogger("inmufacil.auth")

# Create router
router = APIRouter()

# ============================================================================
# Firebase Admin SDK — inicializacion lazy (@Shield)
# ============================================================================

def _get_firebase_app():
    """Inicializa Firebase Admin SDK una sola vez (singleton)."""
    if not firebase_admin._apps:
        import json
        creds_content = os.getenv("FIREBASE_CREDENTIALS_CONTENT")
        creds_path = os.getenv("FIREBASE_CREDENTIALS_PATH") or os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
        if creds_content:
            cred = credentials.Certificate(json.loads(creds_content))
        elif creds_path:
            cred = credentials.Certificate(creds_path)
        else:
            raise RuntimeError(
                "Firebase no configurado. Define FIREBASE_CREDENTIALS_CONTENT o FIREBASE_CREDENTIALS_PATH."
            )
        firebase_admin.initialize_app(cred)
    return firebase_admin.get_app()

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

# JWT Configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "480"))  # 8 h default


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
        # Alert admin (fire-and-forget, non-blocking)
        await send_blocked_registration_alert(
            email=user_data.email,
            full_name=user_data.full_name,
            reason=reason,
            ip_address=client_ip,
            auth_method="email",
        )
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

    # Step 5: Create new user (always particular — ADR-021)
    new_user = User(
        email=user_data.email,
        hashed_password=hashed_password,
        full_name=user_data.full_name,
        user_type=UserType.PARTICULAR,
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
    await send_password_reset_email(user.email, token)

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


# ============================================================================
# Google OAuth Endpoint (@Shield @FrontendProxy)
# ============================================================================

@router.post(
    "/google",
    response_model=GoogleAuthResponse,
    summary="Login / Registro con Google",
    description="""Autentica al usuario usando un Firebase ID token obtenido tras
    Google Sign-In en el cliente. Si el usuario no existe, se crea automaticamente.
    Si el email ya existe con cuenta local, se vincula el google_id.

    **Flujo:**
    1. Cliente obtiene Firebase ID token via google_sign_in
    2. POST /auth/google con {firebase_id_token}
    3. Backend verifica token con Firebase Admin SDK (server-side)
    4. Crea o vincula usuario en base de datos
    5. Devuelve JWT propio de InmuFacil + flag is_new_user
    """,
    tags=["Auth"]
)
async def google_auth(
    payload: GoogleAuthRequest,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    @Shield: Verificacion de Firebase ID token server-side.
    @FrontendProxy: Devuelve mismo contrato Token + is_new_user para onboarding.
    """
    # Paso 1: Verificar Firebase ID token server-side
    try:
        _get_firebase_app()
        decoded = firebase_auth_sdk.verify_id_token(payload.firebase_id_token)
    except (RuntimeError, FileNotFoundError, ValueError, IOError) as exc:
        logger.error(f"[SHIELD] Google auth: Firebase no configurado correctamente: {exc}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Autenticacion con Google no disponible temporalmente"
        )
    except firebase_admin.exceptions.FirebaseError as exc:
        logger.warning(f"[SHIELD] Google auth: Firebase token invalido: {exc}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de Google invalido o expirado"
        )

    google_id: str = decoded["uid"]
    email: str = decoded.get("email", "")
    full_name: str = decoded.get("name", "") or email.split("@")[0]
    email_verified: bool = decoded.get("email_verified", False)

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cuenta de Google no tiene email asociado"
        )

    # Paso 2: Buscar usuario por google_id o por email
    user = db.query(User).filter(User.google_id == google_id).first()
    is_new_user = False

    if user is None:
        user = get_user_by_email(db, email)

        if user is not None:
            # Caso: cuenta local existente — vincular google_id
            user.google_id = google_id
            if email_verified:
                user.email_verified = True
            db.commit()
            db.refresh(user)
            logger.info(f"[AUTH] Google vinculado a cuenta existente: {email}")
        else:
            # Caso: usuario nuevo — validar anti-agencia antes de crear (ADR-021)
            # user_type siempre PARTICULAR; el rol tercero se asigna via token de invitacion
            is_new_user = True
            is_valid, reason = await validate_user_is_not_agency(
                email=email,
                full_name=full_name,
            )
            if not is_valid:
                client_ip = request.client.host if request.client else "unknown"
                log_blocked_attempt(
                    email=email,
                    full_name=full_name,
                    reason=reason,
                    ip_address=client_ip,
                    country="ES"
                )
                logger.warning(f"[SHIELD] Google auth bloqueado: {reason} | Email: {email}")
                await send_blocked_registration_alert(
                    email=email,
                    full_name=full_name,
                    reason=reason,
                    ip_address=client_ip,
                    auth_method="google",
                )
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Registro no permitido: {reason}"
                )
            new_user = User(
                email=email,
                hashed_password=None,
                google_id=google_id,
                full_name=full_name,
                user_type=UserType.PARTICULAR,
                dni_status=DNIStatus.SIN_VERIFICAR,
                email_verified=email_verified,
                dni_verified=False,
                failed_upload_attempts=0
            )
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            user = new_user
            logger.info(f"[AUTH] Nuevo usuario creado via Google: {email} (ID: {user.id})")

    # Paso 3: Emitir JWT propio de InmuFacil
    access_token = create_access_token(
        data={"sub": user.email, "user_id": user.id},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    logger.info(f"[OK] Google auth exitoso: {user.email} (nuevo={is_new_user})")
    return GoogleAuthResponse(
        access_token=access_token,
        token_type="bearer",
        is_new_user=is_new_user,
        created_at=user.created_at,
        updated_at=user.updated_at
    )


# ============================================================================
# Token Renewal Endpoint
# ============================================================================

@router.post(
    "/auth/renew",
    response_model=Token,
    summary="Silent token renewal",
    description=(
        "Exchange a still-valid JWT for a fresh one with a reset expiry window. "
        "Called proactively by the client when the token has less than 1 hour remaining. "
        "No credentials required — authentication is via the current Bearer token."
    ),
    tags=["Auth"],
)
async def renew_token(
    current_user: User = Depends(get_current_active_user),
):
    """Issue a fresh JWT for an already-authenticated user."""
    access_token = create_access_token(
        data={"sub": current_user.email, "user_id": current_user.id},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    logger.info("[AUTH] Token renewed for user_id=%s", current_user.id)
    return {"access_token": access_token, "token_type": "bearer"}
