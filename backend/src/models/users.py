from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, ForeignKey, LargeBinary
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
from .enums import DNIStatus, UserType

class User(Base):
    """User model for authentication and profile management."""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=True)
    google_id = Column(String(128), unique=True, nullable=True, index=True)
    is_active = Column(Boolean, default=True)
    full_name = Column(String, nullable=False)
    dni_status = Column(
        Enum(DNIStatus, native_enum=False),
        default=DNIStatus.SIN_VERIFICAR,
        nullable=True,
    )
    user_type = Column(
        Enum(UserType, native_enum=False),
        default=UserType.PARTICULAR,
        nullable=False
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    encrypted_dni = Column(String, nullable=True)
    encrypted_phone = Column(String, nullable=True)
    dni_hmac = Column(String(64), nullable=True, index=False)

    email_verified = Column(Boolean, default=False, nullable=False)
    verification_token = Column(String, nullable=True)
    token_expires_at = Column(DateTime(timezone=True), nullable=True)

    dni_image_path = Column(String, nullable=True)
    dni_verified = Column(Boolean, default=False, nullable=False)
    rejection_reason = Column(String, nullable=True)

    is_phone_verified = Column(Boolean, default=False, nullable=False)
    failed_upload_attempts = Column(Integer, default=0, nullable=False)

    profile_photo_url = Column(String, nullable=True)
    profile_photo_data = Column(LargeBinary, nullable=True)
    profile_photo_content_type = Column(String(100), nullable=True)

    provider_category = Column(String, nullable=True)
    service_zone = Column(String, nullable=True)

    fcm_token = Column(String(512), nullable=True)

    email_notifications_enabled = Column(Boolean, default=True, nullable=False, server_default="true")

    properties = relationship("Property", back_populates="owner", cascade="all, delete-orphan")
    appointments = relationship("VisitAppointment", back_populates="buyer")

    mortgage_profile = relationship("MortgageProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    simulations = relationship("MortgageSimulation", back_populates="user", cascade="all, delete-orphan")

    notifications = relationship("NotificationLog", back_populates="user", cascade="all, delete-orphan")

    financial_advisor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    financial_advisor = relationship("User", remote_side="User.id", backref="advisees")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, type={self.user_type})>"


class KYCVerification(Base):
    """Model for tracking specific KYC verification requests."""
    __tablename__ = "kyc_verifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    filename = Column(String, nullable=False)
    file_data = Column(LargeBinary, nullable=True)
    file_content_type = Column(String(100), nullable=True)
    dni_encrypted = Column(String, nullable=False)
    status = Column(String, default="pending")
    file_type = Column(String, default="front")
    document_type = Column(String, default="dni")
    rejection_reason = Column(String, nullable=True)
    upload_date = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
