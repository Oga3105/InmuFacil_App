"""
@Shield - Mission 4: Added encrypted fields and MFA verification
@Jules - Database Models (TDD Construction)

SQLAlchemy models for InmuFácil platform.
Implements User model with security and validation fields.
"""

from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, Float, ForeignKey
from sqlalchemy.orm import relationship
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
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)  # Soft delete support
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
    rejection_reason = Column(String, nullable=True)  # Feedback for rejected KYC
    
    # Security Monitoring (@Watcher)
    failed_upload_attempts = Column(Integer, default=0, nullable=False)

    
    # Relationships
    properties = relationship("Property", back_populates="owner", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, type={self.user_type})>"


class KYCVerification(Base):
    """
    Model for tracking specific KYC verification requests.
    Stores metadata about uploaded documents and their status.
    """
    __tablename__ = "kyc_verifications"

    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String, nullable=False)
    dni_encrypted = Column(String, nullable=False)
    status = Column(String, default="pending")
    upload_date = Column(DateTime(timezone=True), server_default=func.now())


class Property(Base):
    """
    Property model for real estate listings.
    Linked to a User (owner).
    """
    __tablename__ = "properties"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    price = Column(Float, nullable=False)
    location = Column(String, nullable=False)
    surface_area = Column(Float, nullable=False)  # in square meters
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="properties")
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
