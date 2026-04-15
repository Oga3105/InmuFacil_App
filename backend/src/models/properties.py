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
    title = Column(String, nullable=True)
    description = Column(String, nullable=True)
    price = Column(Float, nullable=True)
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
    ai_comfort_data_cache = Column(Text, nullable=True)
    ai_comfort_cache_expires_at = Column(DateTime(timezone=True), nullable=True)

    status = Column(Enum(PropertyStatus, native_enum=False), default=PropertyStatus.DRAFT)
    hide_when_reserved = Column(Boolean, default=False)
    allow_visits = Column(Boolean, default=True, nullable=False)

    surface_area = Column(Float, nullable=True)

    property_type = Column(Enum(PropertyType, native_enum=False), default=PropertyType.PISO, nullable=False)
    operation_type = Column(Enum(OperationType, native_enum=False), default=OperationType.VENTA, nullable=False)

    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="properties")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    features = relationship("PropertyFeatures", back_populates="property", uselist=False, cascade="all, delete-orphan")
    legal = relationship("PropertyLegal", back_populates="property", uselist=False, cascade="all, delete-orphan")
    financial = relationship("PropertyFinancial", back_populates="property", uselist=False, cascade="all, delete-orphan")
    environment = relationship("PropertyEnvironment", back_populates="property", uselist=False, cascade="all, delete-orphan")
    media = relationship("PropertyMedia", back_populates="property", cascade="all, delete-orphan", order_by="PropertyMedia.order")
    visit_windows = relationship("VisitWindow", back_populates="property", cascade="all, delete-orphan")
    documents = relationship("PropertyDocument", back_populates="property", cascade="all, delete-orphan")
    valuations = relationship("PropertyValuation", back_populates="property", cascade="all, delete-orphan")


class PropertyFeatures(Base):
    """Physical characteristics of the property."""
    __tablename__ = "property_features"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), unique=True, nullable=False)
    property = relationship("Property", back_populates="features")

    bedrooms = Column(Integer, default=0)
    bathrooms = Column(Integer, default=0)
    construction_year = Column(Integer, nullable=True)

    orientation = Column(Enum(Orientation, native_enum=False), nullable=True)
    heating_type = Column(Enum(HeatingType, native_enum=False), nullable=True)

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

    conservation_state = Column(Enum(ConservationState, native_enum=False), default=ConservationState.BUEN_ESTADO)


class PropertyLegal(Base):
    """Legal and Certification data."""
    __tablename__ = "property_legal"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), unique=True, nullable=False)
    property = relationship("Property", back_populates="legal")

    energy_certification = Column(Enum(EnergyCertification, native_enum=False), default=EnergyCertification.EN_TRAMITE)
    energy_consumption_kwh_m2 = Column(Float, nullable=True)
    emissions_kg_co2_m2 = Column(Float, nullable=True)

    ite_status = Column(Enum(ITEStatus, native_enum=False), default=ITEStatus.PENDIENTE)
    ite_year = Column(Integer, nullable=True)

    cadastral_reference = Column(String, nullable=True)
    nota_simple_status = Column(Enum(NotaSimpleStatus, native_enum=False), default=NotaSimpleStatus.PENDING)


class PropertyFinancial(Base):
    """Financial metrics and investment data."""
    __tablename__ = "property_financial"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), unique=True, nullable=False)
    property = relationship("Property", back_populates="financial")

    ibi_yearly_tax = Column(Float, default=0.0)
    community_fees_monthly = Column(Float, default=0.0)
    estimated_rent_monthly = Column(Float, nullable=True)
    gross_yield = Column(Float, nullable=True)
    price_m2 = Column(Float, nullable=True)


class PropertyEnvironment(Base):
    """Contextual data (Neighborhood Intelligence)."""
    __tablename__ = "property_environment"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), unique=True, nullable=False)
    property = relationship("Property", back_populates="environment")

    noise_level_day_db = Column(Float, nullable=True)
    noise_level_night_db = Column(Float, nullable=True)

    crime_rate_level = Column(Enum(CrimeRate, native_enum=False), default=CrimeRate.BAJO)

    proximity_subway_min = Column(Integer, nullable=True)
    proximity_school_min = Column(Integer, nullable=True)
    healthcare_quality_index = Column(Float, nullable=True)


class PropertyMedia(Base):
    """Multimedia assets for property listings."""
    __tablename__ = "property_media"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    property = relationship("Property", back_populates="media")

    media_type = Column(Enum(MediaType, native_enum=False), default=MediaType.IMAGE, nullable=False)
    file_path = Column(String, nullable=True)
    file_data = Column(LargeBinary, nullable=True)
    content_type = Column(String(100), nullable=True)

    is_main = Column(Boolean, default=False)
    order = Column(Integer, default=0)

    created_at = Column(DateTime(timezone=True), server_default=func.now())


class PropertyDocument(Base):
    """Hito 9: Compliance Documents (Nota Simple, etc). Encrypted at rest."""
    __tablename__ = "property_documents"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    property = relationship("Property", back_populates="documents")

    doc_type = Column(Enum(DocumentType, native_enum=False), nullable=False)
    filename = Column(String, nullable=False)

    file_path = Column(String, nullable=True)
    encrypted_content = Column(Text, nullable=True)
    is_encrypted = Column(Boolean, default=True)

    status = Column(String, default="pending")
    extracted_metadata = Column(Text, nullable=True)

    uploaded_at = Column(DateTime(timezone=True), server_default=func.now())
