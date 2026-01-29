"""
@Shield - Pydantic Schemas (Data Validation & Security)

Request/Response schemas with security best practices.
Prevents sensitive data exposure in API responses.

Row Level Security (RLS) Policy:
- Users can only read/update their own profile data
- Admin operations require elevated permissions
- Sensitive fields (hashed_password) are NEVER exposed in responses

Token Consumption Tracking: ~400 tokens for schema definitions
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


# ============================================================================
# User Schemas
# ============================================================================

class UserBase(BaseModel):
    """
    Base user schema with common fields.
    Does NOT include sensitive data like passwords.
    """
    email: EmailStr
    full_name: str = Field(..., min_length=3, max_length=100)
    user_type: str = Field(default="particular", pattern="^(particular|profesional)$")


class UserCreate(UserBase):
    """
    Schema for user registration.
    Includes password for creation only.
    
    Security Notes:
    - Password is validated but NEVER stored in plain text
    - Password is hashed before database storage
    - This schema is only used for input, never for output
    """
    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(BaseModel):
    """
    Schema for user profile updates.
    RESTRICTION: Email cannot be updated via this endpoint.
    
    Allowed fields:
    - full_name
    - phone (will be encrypted on server side)
    """
    full_name: Optional[str] = Field(None, min_length=3, max_length=100)
    phone: Optional[str] = Field(None, min_length=9, max_length=15)


class UserResponse(UserBase):
    """
    Schema for user data in API responses.
    
    CRITICAL SECURITY: 
    - Does NOT include hashed_password
    - Does NOT include sensitive internal fields
    - Safe to return to clients
    """
    id: int
    dni_status: str
    is_active: bool = True
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    # New Fields for KYC Feedback & Profile Editing
    rejection_reason: Optional[str] = None
    phone: Optional[str] = None  # Decrypted phone number (if available/allowed)

    class Config:
        from_attributes = True  # Allows conversion from SQLAlchemy models


class UserInDB(UserBase):
    """
    Internal use only.
    """
    id: int
    hashed_password: str
    dni_status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ============================================================================
# KYC Schemas
# ============================================================================

class KYCStatusUpdate(BaseModel):
    """
    Schema for Admin KYC review operations.
    """
    status: str = Field(..., pattern="^(validado|rechazado)$")
    rejection_reason: Optional[str] = None


class KYCUploadResponse(BaseModel):
    """
    Response after successful document upload.
    """
    filename: str
    status: str
    message: str


# ============================================================================
# Property Schemas
# ============================================================================

class PropertyBase(BaseModel):
    """
    Base schema for properties.
    """
    title: str = Field(..., min_length=5, max_length=200)
    description: Optional[str] = None
    price: float = Field(..., gt=0)
    location: str = Field(..., min_length=3, max_length=200)
    surface_area: float = Field(..., gt=0)


class PropertyCreate(PropertyBase):
    """
    Schema for property creation. 
    Owner ID is automatically assigned from the authenticated user.
    """
    pass


class PropertyResponse(PropertyBase):
    """
    Schema for property details in responses.
    """
    id: int
    owner_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ============================================================================
# Token Schemas
# ============================================================================

class Token(BaseModel):
    """
    JWT token response schema.
    """
    access_token: str
    token_type: str = "bearer"
    
    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer"
            }
        }


class TokenData(BaseModel):
    """
    Token payload data (decoded JWT).
    """
    email: Optional[str] = None
    user_id: Optional[int] = None
