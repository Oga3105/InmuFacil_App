"""
@Shield - Pydantic Schemas (Data Validation & Security)
Updated for Mission 5: Advanced Property Data Intelligence.

Request/Response schemas with security best practices.
Prevents sensitive data exposure in API responses.
"""

from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List
from datetime import datetime
from backend.src.models import (
    PropertyType, OperationType, Orientation, HeatingType, 
    ConservationState, EnergyCertification, ITEStatus, 
    NotaSimpleStatus, CrimeRate, MediaType
)


# ============================================================================
# User Schemas
# ============================================================================

class UserBase(BaseModel):
    """Base user schema."""
    email: EmailStr
    full_name: str = Field(..., min_length=3, max_length=100)
    user_type: str = Field(default="particular", pattern="^(particular|profesional)$")


class UserCreate(UserBase):
    """Schema for user registration."""
    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(BaseModel):
    """Schema for user profile updates."""
    full_name: Optional[str] = Field(None, min_length=3, max_length=100)
    phone: Optional[str] = Field(None, min_length=9, max_length=15)


class UserResponse(UserBase):
    """Schema for user data in API responses."""
    id: int
    dni_status: str
    is_active: bool = True
    created_at: datetime
    updated_at: Optional[datetime] = None
    rejection_reason: Optional[str] = None
    phone: Optional[str] = None

    class Config:
        from_attributes = True


class UserInDB(UserBase):
    """Internal use only."""
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
    status: str = Field(..., pattern="^(validado|rechazado)$")
    rejection_reason: Optional[str] = None


class KYCUploadResponse(BaseModel):
    filename: str
    status: str
    message: str


# ============================================================================
# Property Satellite Schemas (Nested)
# ============================================================================

class PropertyFeaturesSchema(BaseModel):
    bedrooms: int = Field(0, ge=0)
    bathrooms: int = Field(0, ge=0)
    construction_year: Optional[int] = Field(None, ge=1800, le=2100)
    orientation: Optional[Orientation] = None
    heating_type: Optional[HeatingType] = None
    has_lift: bool = False
    has_ac: bool = False
    has_heating: bool = False
    has_terrace: bool = False
    has_pool: bool = False
    has_garden: bool = False
    conservation_state: ConservationState = ConservationState.BUEN_ESTADO
    
    class Config:
        use_enum_values = True


class PropertyLegalSchema(BaseModel):
    energy_certification: EnergyCertification = EnergyCertification.EN_TRAMITE
    energy_consumption_kwh_m2: Optional[float] = None
    emissions_kg_co2_m2: Optional[float] = None
    ite_status: ITEStatus = ITEStatus.PENDIENTE
    ite_year: Optional[int] = None
    cadastral_reference: Optional[str] = None
    nota_simple_status: NotaSimpleStatus = NotaSimpleStatus.PENDING

    class Config:
        use_enum_values = True


class PropertyFinancialSchema(BaseModel):
    ibi_yearly_tax: float = Field(0.0, ge=0)
    community_fees_monthly: float = Field(0.0, ge=0)
    estimated_rent_monthly: Optional[float] = None
    # Calculated fields like gross_yield are response-only mostly, but allowed here
    
    class Config:
        use_enum_values = True


class PropertyEnvironmentSchema(BaseModel):
    noise_level_day_db: Optional[float] = None
    noise_level_night_db: Optional[float] = None
    crime_rate_level: CrimeRate = CrimeRate.BAJO
    proximity_subway_min: Optional[int] = None
    proximity_school_min: Optional[int] = None
    healthcare_quality_index: Optional[float] = None

    class Config:
        use_enum_values = True


# ============================================================================
# Property Media Schemas
# ============================================================================

class PropertyMediaResponse(BaseModel):
    """
    Schema for property media (Images, Videos).
    """
    id: int
    media_type: MediaType
    file_path: str
    is_main: bool
    order: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class PropertyMediaCreate(BaseModel):
    """
    Schema for manually adding media links (Videos/Tours).
    Images are handled via Multipart upload, not JSON body.
    """
    media_type: MediaType = Field(..., description="Must be video or virtual_tour")
    file_path: str = Field(..., description="URL to the video or tour")
    is_main: bool = False
    order: int = 0


# ============================================================================
# Property Core Schemas
# ============================================================================

class PropertyBase(BaseModel):
    """Base schema for properties."""
    title: str = Field(..., min_length=5, max_length=200)
    description: Optional[str] = None
    price: float = Field(..., gt=0)
    location: str = Field(..., min_length=3, max_length=200)
    surface_area: float = Field(..., gt=0)
    
    property_type: PropertyType = PropertyType.PISO
    operation_type: OperationType = OperationType.VENTA


class PropertyCreate(PropertyBase):
    """
    Schema for property creation. 
    Includes optional nested data for advanced intelligence.
    """
    features: Optional[PropertyFeaturesSchema] = None
    legal: Optional[PropertyLegalSchema] = None
    financial: Optional[PropertyFinancialSchema] = None
    # Environment usually populated by system, but allowed for manual override if needed
    
    class Config:
        use_enum_values = True


class PropertyResponse(PropertyBase):
    """
    Schema for property details in responses.
    """
    id: int
    owner_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    features: Optional[PropertyFeaturesSchema] = None
    legal: Optional[PropertyLegalSchema] = None
    financial: Optional[PropertyFinancialSchema] = None
    environment: Optional[PropertyEnvironmentSchema] = None
    
    # Media list
    media: List[PropertyMediaResponse] = []
    
    # Computed fields
    gross_yield: Optional[float] = None
    price_m2: Optional[float] = None

    class Config:
        from_attributes = True


# ============================================================================
# Token Schemas
# ============================================================================

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"



class TokenData(BaseModel):
    email: Optional[str] = None
    user_id: Optional[int] = None


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    token: str = Field(..., min_length=6, max_length=6)


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    email: EmailStr
    token: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=8, max_length=100)



# ============================================================================
# Visits System Schemas
# ============================================================================

class VisitWindowCreate(BaseModel):
    """
    Schema for creating a visit availability window.
    """
    property_id: int
    start_time: datetime
    end_time: datetime
    slot_duration_minutes: int = 20

    @validator('end_time')
    def validate_times(cls, v, values):
        if 'start_time' in values and v <= values['start_time']:
            raise ValueError('end_time must be after start_time')
        return v


class VisitWindowResponse(BaseModel):
    id: int
    property_id: int
    start_time: datetime
    end_time: datetime
    slot_duration_minutes: int
    created_at: datetime

    class Config:
        from_attributes = True


class VisitSlotResponse(BaseModel):
    """
    Calculated available slot.
    """
    start_time: datetime
    end_time: datetime
    is_available: bool = True
    window_id: int


class VisitRequest(BaseModel):
    """
    Buyer request to book a specific slot.
    """
    window_id: int
    start_time: datetime


class VisitAppointmentResponse(BaseModel):
    """
    Full appointment details.
    """
    id: int
    window_id: int
    buyer_id: int
    start_time: datetime
    status: str # requested, approved, rejected
    created_at: datetime
    
    # Optional: include basic user/property info if needed, but keeping it light for now
    
    class Config:
        from_attributes = True


