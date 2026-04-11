from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, ForeignKey, LargeBinary
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
from .enums import DNIStatus, UserType

class User(Base):
    """
    User model for authentication and profile management.
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=True)  # NULL para cuentas Google-only
    google_id = Column(String(128), unique=True, nullable=True, index=True)  # Google OAuth sub
    is_active = Column(Boolean, default=True)  # Soft delete support
    full_name = Column(String, nullable=False)
    dni_status = Column(
        Enum(DNIStatus),
        default=DNIStatus.SIN_VERIFICAR,
        nullable=True,
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
    # HMAC-SHA256 fingerprint for DNI uniqueness — non-reversible, GDPR-safe.
    # UNIQUE partial index (WHERE NOT NULL) defined in migration.
    dni_hmac = Column(String(64), nullable=True, index=False)  # unique enforced at DB level
    
    # MFA Email Verification (@Shield)
    email_verified = Column(Boolean, default=False, nullable=False)
    verification_token = Column(String, nullable=True)  # Hashed token
    token_expires_at = Column(DateTime(timezone=True), nullable=True)
    
    # KYC Document Verification (@Jules)
    dni_image_path = Column(String, nullable=True)  # Path to redacted image
    dni_verified = Column(Boolean, default=False, nullable=False)
    rejection_reason = Column(String, nullable=True)  # Feedback for rejected KYC
    
    # Phone Verification (Firebase SMS — Hito Chat)
    is_phone_verified = Column(Boolean, default=False, nullable=False)

    # Security Monitoring (@Watcher)
    failed_upload_attempts = Column(Integer, default=0, nullable=False)

    # Profile Photo — stored as BYTEA; profile_photo_url kept for legacy rows only
    profile_photo_url = Column(String, nullable=True)
    profile_photo_data = Column(LargeBinary, nullable=True)
    profile_photo_content_type = Column(String(100), nullable=True)

    # Provider Fields (Hito 17 - Service Marketplace)
    provider_category = Column(String, nullable=True) # e.g. "NOTARY", "VALUER"
    service_zone = Column(String, nullable=True) # e.g. "Madrid", "Barcelona"

    # Push Notifications — FCM device token (V17 Notification Center)
    fcm_token = Column(String(512), nullable=True)

    # Email Notification Preferences (@Shield GDPR opt-out)
    # Controls whether user receives emails triggered by OTHER users' actions.
    # Own-action confirmation emails are always sent regardless of this flag.
    email_notifications_enabled = Column(Boolean, default=True, nullable=False, server_default="true")

    # Relationships
    # Using string references to avoid circular imports
    properties = relationship("Property", back_populates="owner", cascade="all, delete-orphan")
    appointments = relationship("VisitAppointment", back_populates="buyer")

    # Hito 11: Financing
    mortgage_profile = relationship("MortgageProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    simulations = relationship("MortgageSimulation", back_populates="user", cascade="all, delete-orphan")

    # V17: Notification Center
    notifications = relationship("NotificationLog", back_populates="user", cascade="all, delete-orphan")
    
    # Advisor Relationship (Self-Referential)
    financial_advisor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    financial_advisor = relationship("User", remote_side="User.id", backref="advisees")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, type={self.user_type})>"

class KYCVerification(Base):
    """
    Model for tracking specific KYC verification requests.
    Stores metadata about uploaded documents and their status.
    """
    __tablename__ = "kyc_verifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    filename = Column(String, nullable=False)
    file_data = Column(LargeBinary, nullable=True)
    file_content_type = Column(String(100), nullable=True)
    dni_encrypted = Column(String, nullable=False)
    status = Column(String, default="pending")
    file_type = Column(String, default="front")  # front / back / selfie
    document_type = Column(String, default="dni")  # dni / nie / pasaporte
    rejection_reason = Column(String, nullable=True)
    upload_date = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
