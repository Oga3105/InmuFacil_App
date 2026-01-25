"""
@Jules - Database Models (TDD Construction)

SQLAlchemy models for InmuFácil platform.
Implements User model with security and validation fields.
"""

from sqlalchemy import Column, Integer, String, Enum, DateTime
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
    
    Security Notes:
    - Passwords are NEVER stored in plain text
    - Email is unique and indexed for fast lookups
    - Row Level Security (RLS) ensures users can only access their own data
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

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, type={self.user_type})>"
