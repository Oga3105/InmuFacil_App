"""
@Shield - Pydantic Schemas (Data Validation & Security)
Updated for Mission 5: Advanced Property Data Intelligence.

Request/Response schemas with security best practices.
Prevents sensitive data exposure in API responses.
"""

from pydantic import BaseModel, EmailStr, Field, validator, model_validator, computed_field, ConfigDict
from typing import Literal, Optional, List
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
    user_type: str = Field(default="particular", pattern="^(particular|tercero|admin|provider|financiero)$")


class UserCreate(UserBase):
    """Schema for user registration."""
    password: str = Field(..., min_length=8, max_length=100)


class UserUpdate(BaseModel):
    """Schema for user profile updates."""
    full_name: Optional[str] = Field(None, min_length=3, max_length=100)
    phone: Optional[str] = Field(None, min_length=9, max_length=15)
    email_notifications_enabled: Optional[bool] = None


class UserResponse(UserBase):
    """Schema for user data in API responses."""
    id: int
    dni_status: str
    is_active: bool = True
    created_at: datetime
    updated_at: Optional[datetime] = None
    rejection_reason: Optional[str] = None
    phone: Optional[str] = None
    profile_photo_url: Optional[str] = None
    email_notifications_enabled: bool = True

    class Config:
        from_attributes = True


class UserInDB(UserBase):
    """Internal use only."""
    id: int
    hashed_password: str
    dni_status: str


# ============================================================================
# Google OAuth Schemas (@Shield)
# ============================================================================

class GoogleAuthRequest(BaseModel):
    """Schema para autenticacion via Google. Recibe Firebase ID token del cliente."""
    firebase_id_token: str = Field(..., min_length=10)


class GoogleAuthResponse(BaseModel):
    """Respuesta del endpoint /auth/google."""
    access_token: str
    token_type: str = "bearer"
    is_new_user: bool = False
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


class KYCStatusResponse(BaseModel):
    status: str
    rejection_reason: Optional[str] = None
    upload_date: Optional[datetime] = None
    document_type: Optional[str] = None


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
    has_garage: bool = False
    has_storage: bool = False
    has_wardrobes: bool = False
    has_exterior: bool = False
    has_accessibility: bool = False
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
    file_path is nullable (images stored as BYTEA have no path).
    url is computed: images → /api/v1/properties/media/{id}/file, videos → file_path.
    """
    model_config = ConfigDict(from_attributes=True)

    id: int
    media_type: MediaType
    file_path: Optional[str] = None
    is_main: bool
    order: int
    created_at: datetime

    @computed_field
    @property
    def url(self) -> str:
        if self.media_type == MediaType.IMAGE:
            return f"/api/v1/properties/media/{self.id}/file"
        return self.file_path or ""


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
    location: Optional[str] = Field(None, max_length=200)
    surface_area: float = Field(..., gt=0)

    # Structured address
    street: Optional[str] = None
    street_number: Optional[str] = None
    floor: Optional[str] = None
    city: Optional[str] = None
    province: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    hide_exact_location: bool = False
    allow_visits: bool = True
    ai_comfort_consent: bool = False

    property_type: PropertyType = PropertyType.PISO
    operation_type: OperationType = OperationType.VENTA


class PropertyCreate(PropertyBase):
    """
    Schema for property creation.
    Includes optional nested data for advanced intelligence.
    status defaults to published; pass 'draft' to save without full validation.
    """
    status: Optional[str] = Field(None, pattern="^(draft|published|unpublished|reserved|sold)$")
    features: Optional[PropertyFeaturesSchema] = None
    legal: Optional[PropertyLegalSchema] = None
    financial: Optional[PropertyFinancialSchema] = None

    class Config:
        use_enum_values = True


class PropertyDraftCreate(BaseModel):
    """
    Schema for saving a draft — all fields optional.
    Only property_type is expected; everything else may be empty.
    """
    status: str = Field("draft", pattern="^(draft|published|unpublished)$")
    property_type: Optional[str] = None
    operation_type: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = Field(None, ge=0)
    surface_area: Optional[float] = Field(None, ge=0)
    location: Optional[str] = None
    street: Optional[str] = None
    street_number: Optional[str] = None
    floor: Optional[str] = None
    city: Optional[str] = None
    province: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    hide_exact_location: bool = False
    ai_comfort_consent: bool = False
    features: Optional[PropertyFeaturesSchema] = None

    class Config:
        use_enum_values = True


class StatusUpdate(BaseModel):
    """Schema for PATCH /{id}/status endpoint."""
    status: Literal["draft", "published", "unpublished"]


class PropertyResponse(PropertyBase):
    """
    Schema for property details in responses.
    Overrides required fields as Optional to support draft records with empty data.
    """
    # Drafts may have empty required fields — make them optional in responses
    title: Optional[str] = None
    price: Optional[float] = None
    surface_area: Optional[float] = None

    id: int
    owner_id: int
    status: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    previous_price: Optional[float] = None
    price_updated_at: Optional[datetime] = None

    features: Optional[PropertyFeaturesSchema] = None
    legal: Optional[PropertyLegalSchema] = None
    financial: Optional[PropertyFinancialSchema] = None
    environment: Optional[PropertyEnvironmentSchema] = None

    # Media list
    media: List[PropertyMediaResponse] = []

    # Computed fields
    gross_yield: Optional[float] = None
    price_m2: Optional[float] = None

    # AI Comfort Index consent flag (exposed so frontend knows whether to show CTA)
    ai_comfort_consent: bool = False

    # Owner info (populated from the ORM relationship)
    owner_name: Optional[str] = None
    owner_is_verified: Optional[bool] = None
    owner_photo_url: Optional[str] = None

    @model_validator(mode='before')
    @classmethod
    def populate_owner_info(cls, values):
        if not hasattr(values, '__dict__'):
            return values
        owner = getattr(values, 'owner', None)
        if owner is not None:
            # Inject into the object's __dict__ so Pydantic picks them up
            values.__dict__.setdefault('owner_name', getattr(owner, 'full_name', None))
            dni = getattr(owner, 'dni_status', None)
            dni_str = (dni.value if hasattr(dni, 'value') else str(dni) if dni else '').lower()
            values.__dict__.setdefault('owner_is_verified', dni_str == 'validado')
            values.__dict__.setdefault('owner_photo_url', getattr(owner, 'profile_photo_url', None))
        return values

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


class ChangePassword(BaseModel):
    current_password: str = Field(..., min_length=8, max_length=100)
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
    # Filtering Questions
    q_solvency: str = Field(..., description="Funding status (Contado, Hipoteca aprobada...)")
    q_timeline: str = Field(..., description="Desired move-in date")
    q_maturity: str = Field(..., description="Experience level (First visit, etc)")


class VisitAppointmentResponse(BaseModel):
    """
    Full appointment details.
    """
    id: int
    window_id: int
    buyer_id: int
    start_time: datetime
    status: str # requested, approved, rejected
    
    # Answers (Visible to Seller)
    q_solvency: Optional[str] = None
    q_timeline: Optional[str] = None
    q_maturity: Optional[str] = None
    
    created_at: datetime
    
    # Optional: include basic user/property info if needed, but keeping it light for now
    
    class Config:
        from_attributes = True


