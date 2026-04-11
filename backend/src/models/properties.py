from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, Float, ForeignKey, Text, LargeBinary
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
from .enums import (
    PropertyStatus, PropertyType, OperationType, Orientation, HeatingType, 
    ConservationState, EnergyCertification, ITEStatus, NotaSimpleStatus, 
    CrimeRate, MediaType, DocumentType
)

class Property(Base):
    """
    Property model (CORE). Contains essential indexing data.
    Linked to satellite tables for extended intelligence.
    """
    __tablename__ = "properties"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    price = Column(Float, nullable=False)
    previous_price = Column(Float, nullable=True)
    price_updated_at = Column(DateTime(timezone=True), nullable=True)
    location = Column(String, nullable=True)

    # Structured address fields
    street         = Column(String, nullable=True)
    street_number  = Column(String, nullable=True)
    floor          = Column(String, nullable=True)
    city           = Column(String, nullable=True)
    province       = Column(String, nullable=True)
    postal_code    = Column(String, nullable=True)
    latitude       = Column(Float, nullable=True)
    longitude      = Column(Float, nullable=True)
    hide_exact_location = Column(Boolean, default=False)

    # AI Comfort Index — GDPR consent and result cache
    ai_comfort_consent = Column(Boolean, default=False, nullable=False)
    ai_comfort_consent_date = Column(DateTime(timezone=True), nullable=True)
    ai_comfort_data_cache = Column(Text, nullable=True)   # JSON string with ComfortIndexResponse
    ai_comfort_cache_expires_at = Column(DateTime(timezone=True), nullable=True)

    status = Column(Enum(PropertyStatus), default=PropertyStatus.PUBLISHED)
    hide_when_reserved = Column(Boolean, default=False) # Hito 8: Visibility Config
    allow_visits = Column(Boolean, default=True, nullable=False)
    
    # Basic dimensions (often filtered)
    surface_area = Column(Float, nullable=False)  # in square meters
    
    # Classification
    property_type = Column(Enum(PropertyType), default=PropertyType.PISO, nullable=False)
    operation_type = Column(Enum(OperationType), default=OperationType.VENTA, nullable=False)
    
    # Ownership
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="properties")
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Satellite Relationships (1:1)
    features = relationship("PropertyFeatures", back_populates="property", uselist=False, cascade="all, delete-orphan")
    legal = relationship("PropertyLegal", back_populates="property", uselist=False, cascade="all, delete-orphan")
    financial = relationship("PropertyFinancial", back_populates="property", uselist=False, cascade="all, delete-orphan")
    environment = relationship("PropertyEnvironment", back_populates="property", uselist=False, cascade="all, delete-orphan")
    
    # Media Relationship (1:N)
    media = relationship("PropertyMedia", back_populates="property", cascade="all, delete-orphan", order_by="PropertyMedia.order")
    
    # Visits Relationship (1:N)
    visit_windows = relationship("VisitWindow", back_populates="property", cascade="all, delete-orphan")
    
    # Compliance Documents (1:N)
    documents = relationship("PropertyDocument", back_populates="property", cascade="all, delete-orphan")
    
    # Valuations (Hito 10) (1:N)
    valuations = relationship("PropertyValuation", back_populates="property", cascade="all, delete-orphan")


class PropertyFeatures(Base):
    """
    Physical characteristics of the property.
    """
    __tablename__ = "property_features"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), unique=True, nullable=False)
    property = relationship("Property", back_populates="features")
    
    bedrooms = Column(Integer, default=0)
    bathrooms = Column(Integer, default=0)
    construction_year = Column(Integer, nullable=True)
    
    orientation = Column(Enum(Orientation), nullable=True)
    heating_type = Column(Enum(HeatingType), nullable=True)
    
    has_lift = Column(Boolean, default=False)
    has_ac = Column(Boolean, default=False)
    has_heating = Column(Boolean, default=False)
    has_terrace = Column(Boolean, default=False)
    has_pool = Column(Boolean, default=False)
    has_garden = Column(Boolean, default=False)
    has_garage = Column(Boolean, default=False)
    has_storage = Column(Boolean, default=False)
    has_wardrobes = Column(Boolean, default=False)
    has_exterior = Column(Boolean, default=False)
    has_accessibility = Column(Boolean, default=False)

    conservation_state = Column(Enum(ConservationState), default=ConservationState.BUEN_ESTADO)


class PropertyLegal(Base):
    """
    Legal and Certification data.
    """
    __tablename__ = "property_legal"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), unique=True, nullable=False)
    property = relationship("Property", back_populates="legal")
    
    energy_certification = Column(Enum(EnergyCertification), default=EnergyCertification.EN_TRAMITE)
    energy_consumption_kwh_m2 = Column(Float, nullable=True)
    emissions_kg_co2_m2 = Column(Float, nullable=True)
    
    ite_status = Column(Enum(ITEStatus), default=ITEStatus.PENDIENTE)
    ite_year = Column(Integer, nullable=True)
    
    cadastral_reference = Column(String, nullable=True)
    nota_simple_status = Column(Enum(NotaSimpleStatus), default=NotaSimpleStatus.PENDING)


class PropertyFinancial(Base):
    """
    Financial metrics and investment data.
    """
    __tablename__ = "property_financial"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), unique=True, nullable=False)
    property = relationship("Property", back_populates="financial")
    
    ibi_yearly_tax = Column(Float, default=0.0)
    community_fees_monthly = Column(Float, default=0.0)
    
    # Investment Logic
    estimated_rent_monthly = Column(Float, nullable=True)  # Can be auto-calculated or manual
    gross_yield = Column(Float, nullable=True)  # (Annual Rent / Purchase Price) * 100
    price_m2 = Column(Float, nullable=True)  # Price / Surface Area


class PropertyEnvironment(Base):
    """
    Contextual data (Neighborhood Intelligence).
    To be populated via External APIs or Data Caching.
    """
    __tablename__ = "property_environment"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), unique=True, nullable=False)
    property = relationship("Property", back_populates="environment")
    
    # Noise (MER Data)
    noise_level_day_db = Column(Float, nullable=True)
    noise_level_night_db = Column(Float, nullable=True)
    
    # Safety
    crime_rate_level = Column(Enum(CrimeRate), default=CrimeRate.BAJO)
    
    # Services
    proximity_subway_min = Column(Integer, nullable=True)
    proximity_school_min = Column(Integer, nullable=True)
    healthcare_quality_index = Column(Float, nullable=True)  # 0-100 Score


class PropertyMedia(Base):
    """
    Multimedia assets for property listings.
    Supports Images (local/cloud), Videos (links), Tours (links).
    """
    __tablename__ = "property_media"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    property = relationship("Property", back_populates="media")
    
    media_type = Column(Enum(MediaType), default=MediaType.IMAGE, nullable=False)
    file_path = Column(String, nullable=True)    # URL for VIDEO/VIRTUAL_TOUR; NULL for IMAGE
    file_data = Column(LargeBinary, nullable=True)  # Binary data for IMAGE (stored in DB)
    content_type = Column(String(100), nullable=True)  # e.g. "image/jpeg"

    is_main = Column(Boolean, default=False)  # Cover image
    order = Column(Integer, default=0)

    created_at = Column(DateTime(timezone=True), server_default=func.now())


class PropertyDocument(Base):
    """
    Hito 9: Compliance Documents (Nota Simple, etc).
    Encrypted at rest if sensitive (Nota Simple).
    """
    __tablename__ = "property_documents"
    
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    property = relationship("Property", back_populates="documents")
    
    doc_type = Column(Enum(DocumentType), nullable=False)
    filename = Column(String, nullable=False)
    
    # Security: Encrypted content stored directly in DB (no filesystem)
    file_path = Column(String, nullable=True)          # deprecated — legacy rows only
    encrypted_content = Column(Text, nullable=True)    # AES-256 encrypted, base64-wrapped
    is_encrypted = Column(Boolean, default=True)
    
    # Compliance
    status = Column(String, default="pending") # pending, verified, rejected
    extracted_metadata = Column(Text, nullable=True) # JSON with OCR results
    
    uploaded_at = Column(DateTime(timezone=True), server_default=func.now())
