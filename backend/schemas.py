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
    All fields are optional to allow partial updates.
    
    RLS Policy: Users can only update their own profile
    """
    full_name: Optional[str] = Field(None, min_length=3, max_length=100)
    email: Optional[EmailStr] = None


class UserResponse(UserBase):
    """
    Schema for user data in API responses.
    
    CRITICAL SECURITY: 
    - Does NOT include hashed_password
    - Does NOT include sensitive internal fields
    - Safe to return to clients
    
    RLS Policy: Users can only view their own profile data
    """
    id: int
    dni_status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True  # Allows conversion from SQLAlchemy models


class UserInDB(UserBase):
    """
    Schema representing user data as stored in database.
    Used internally only, NEVER returned to clients.
    
    Security Notes:
    - Includes hashed_password for authentication
    - Only used for internal operations
    - Never exposed via API endpoints
    """
    id: int
    hashed_password: str
    dni_status: str
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
    Returned after successful login.
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
    Used internally for authentication.
    """
    email: Optional[str] = None
    user_id: Optional[int] = None
