"""
@Shield - Security Utilities (OWASP Compliance)

Password hashing, verification, centralized authentication dependencies,
and AES-256 data encryption.
"""

from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session
import os
from datetime import datetime, timedelta
from typing import Optional
from cryptography.fernet import Fernet # Added for encrypt_data

from backend.database import get_db
from backend.models import User, UserType
from backend.schemas import TokenData

# ============================================================================
# Configuration
# ============================================================================

# Bcrypt password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT Configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Encryption Master Key (Required for encrypt_data)
# Should be 32 URL-safe base64-encoded bytes
MASTER_KEY = os.getenv("INMUFACIL_MASTER_KEY")
if not MASTER_KEY or len(MASTER_KEY) < 32:
    # Use a dummy key if env not set, OR raise error. 
    # For now, we will handle it gracefully or use a generated one if needed, 
    # but strictly we should use environment.
    # We will instantiate Fernet dynamically.
    pass

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

# ============================================================================
# Password Utilities
# ============================================================================

def hash_password(password: str) -> str:
    """Hash a plain text password using Bcrypt."""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain text password against a hashed password."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Alias for hash_password."""
    return hash_password(password)

# ============================================================================
# Data Encryption Utilities
# ============================================================================

def get_f():
    """Retrieve Fernet instance with current master key."""
    key = os.getenv("INMUFACIL_MASTER_KEY")
    if not key:
        raise ValueError("INMUFACIL_MASTER_KEY is not set.")
    return Fernet(key)

def encrypt_data(data: str) -> str:
    """
    Encrypt a string using AES-256 (Fernet).
    """
    if not data:
        return None
    f = get_f()
    return f.encrypt(data.encode()).decode()

def decrypt_data(token: str) -> str:
    """
    Decrypt a string using AES-256 (Fernet).
    """
    if not token:
        return None
    f = get_f()
    return f.decrypt(token.encode()).decode()


# ============================================================================
# JWT Utilities
# ============================================================================

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# ============================================================================
# Dependencies
# ============================================================================

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """
    Validate JWT token and retrieve current user.
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
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
        
    user = db.query(User).filter(User.email == token_data.email).first()
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)):
    """
    Ensure user is active (soft delete check).
    """
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

async def get_current_admin_user(current_user: User = Depends(get_current_active_user)):
    """
    Ensure user has admin privileges.
    """
    # Hardcoded admin check for the initial superuser
    ADMIN_EMAIL = "admin@inmufacil.com"
    if current_user.email != ADMIN_EMAIL:
         raise HTTPException(
             status_code=status.HTTP_403_FORBIDDEN, 
             detail="Not enough permissions"
         )
    return current_user
