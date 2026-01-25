"""
@Shield - Mission 4: Added encrypted fields and MFA verification
@Jules - Database Models (TDD Construction)

SQLAlchemy models for InmuFácil platform.
Implements User model with security and validation fields.
"""

from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean
from sqlalchemy.sql import func
import enum

from .database import Base


class DNIStatus(str, enum.Enum):
    """DNI validation status enumeration"""
    PENDIENTE = "pendiente"
    VALIDADO = "validado"


class UserType(str, enum.Enum):
    """User type enumeration"""
    PARTICULAR = "particular"
    PROFESIONAL = "profesional"


class User(Base):
    """
    User model for authentication and profile management.
    
    Fields:
    - id: Primary key
    - email: Unique user email (used for login)
    - hashed_password: Bcrypt hashed password (never store plain text)
    - full_name: User's full legal name
    - dni_status: DNI validation status (pendiente/validado)
    - user_type: Account type (particular/profesional)
    - created_at: Timestamp of account creation
    - updated_at: Timestamp of last update
    
    Mission 4 - KYC & Security Fields:
    - encrypted_dni: AES-256-GCM encrypted DNI number
    - encrypted_phone: AES-256-GCM encrypted phone number
    - email_verified: MFA email verification status
    - verification_token: Current MFA token (hashed)
    - token_expires_at: MFA token expiration timestamp
    - dni_image_path: Path to redacted DNI image
    - dni_verified: Whether DNI document has been verified
    - failed_upload_attempts: Counter for brute force prevention
    
    Security Notes:
    - Passwords are NEVER stored in plain text
    - DNI and phone are encrypted with AES-256-GCM
    - Email is unique and indexed for fast lookups
    - Row Level Security (RLS) ensures users can only access their own data
    - MFA tokens expire after 15 minutes
    - Account locks after 3 failed DNI uploads (MITRE T1110)
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    dni_status = Column(
        Enum(DNIStatus), 
        default=DNIStatus.PENDIENTE, 
        nullable=False
    )
    user_type = Column(
        Enum(UserType), 
        default=UserType.PARTICULAR, 
        nullable=False
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Mission 4 - KYC & Security Fields (@Shield)
    encrypted_dni = Column(String, nullable=True)  # AES-256-GCM encrypted
    encrypted_phone = Column(String, nullable=True)  # AES-256-GCM encrypted
    
    # MFA Email Verification (@Shield)
    email_verified = Column(Boolean, default=False, nullable=False)
    verification_token = Column(String, nullable=True)  # Hashed token
    token_expires_at = Column(DateTime(timezone=True), nullable=True)
    
    # KYC Document Verification (@Jules)
    dni_image_path = Column(String, nullable=True)  # Path to redacted image
    dni_verified = Column(Boolean, default=False, nullable=False)
    
    # Security Monitoring (@Watcher)
    failed_upload_attempts = Column(Integer, default=0, nullable=False)

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, type={self.user_type})>"
