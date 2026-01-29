"""
@Shield - Mission 4: Added encrypted fields and MFA verification
@Jules - Database Models (TDD Construction)

SQLAlchemy models for InmuFácil platform.
Implements User model with security and validation fields.
Updated for Mission 5: Advanced Property Data Intelligence.
"""

from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

from .database import Base


# ============================================================================
# Enums
# ============================================================================

class DNIStatus(str, enum.Enum):
    """DNI validation status enumeration"""
    PENDIENTE = "pendiente"
    VALIDADO = "validado"


class UserType(str, enum.Enum):
    """User type enumeration"""
    PARTICULAR = "particular"
    PROFESIONAL = "profesional"


class PropertyType(str, enum.Enum):
    PISO = "piso"
    CHALET = "chalet"
    LOCAL = "local"
    OFICINA = "oficina"
    TERRENO = "terreno"
    EDIFICIO = "edificio"


class OperationType(str, enum.Enum):
    VENTA = "venta"
    ALQUILER = "alquiler"
    BTR = "btr"  # Build to Rent
    INVERSION = "inversion"


class Orientation(str, enum.Enum):
    NORTE = "norte"
    SUR = "sur"
    ESTE = "este"
    OESTE = "oeste"
    NORESTE = "noreste"
    NOROESTE = "noroeste"
    SURESTE = "sureste"
    SUROESTE = "suroeste"

class PropertyStatus(str, enum.Enum):
    PUBLISHED = "published"
    RESERVED = "reserved" # Hito 8
    SOLD = "sold"


class DocumentType(str, enum.Enum):
    NOTA_SIMPLE = "nota_simple"
    CERTIFICADO_ENERGETICO = "certificado_energetico"
    RECIBO_IBI = "recibo_ibi"
    ESTATUTOS = "estatutos"
    OTRO = "otro"


class HeatingType(str, enum.Enum):
    GAS_NATURAL = "gas_natural"
    ELECTRICA = "electrica"
    CENTRAL = "central"
    AEROTERMIA = "aerotermia"
    OTRO = "otro"


class ConservationState(str, enum.Enum):
    A_ESTRENAR = "a_estrenar"
    BUEN_ESTADO = "buen_estado"
    A_REFORMAR = "a_reformar"


class EnergyCertification(str, enum.Enum):
    A = "A"
    B = "B"
    C = "C"
    D = "D"
    E = "E"
    F = "F"
    G = "G"
    EXENTO = "exento"
    EN_TRAMITE = "en_tramite"


class ITEStatus(str, enum.Enum):
    PASADA = "pasada"
    PENDIENTE = "pendiente"
    DESFAVORABLE = "desfavorable"
    NO_OBLIGADO = "no_obligado"


class NotaSimpleStatus(str, enum.Enum):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"


class CrimeRate(str, enum.Enum):
    BAJO = "bajo"
    MEDIO = "medio"
    ALTO = "alto"


class MediaType(str, enum.Enum):
    IMAGE = "image"
    VIDEO = "video"
    VIRTUAL_TOUR = "virtual_tour"

class VisitStatus(str, enum.Enum):
    REQUESTED = "requested"
    APPROVED = "approved"
    REJECTED = "rejected"
    # Execution States
    COMPLETED = "completed"
    NO_SHOW = "no_show"
    CANCELLED = "cancelled"


class OfferStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    COUNTERED = "countered"
    PAUSED = "paused" # For when another offer is accepted


# ============================================================================
# User Models
# ============================================================================

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
    appointments = relationship("VisitAppointment", back_populates="buyer")

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


# ============================================================================
# Property Core & Satellites
# ============================================================================

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
    location = Column(String, nullable=False)
    
    status = Column(Enum(PropertyStatus), default=PropertyStatus.PUBLISHED)
    hide_when_reserved = Column(Boolean, default=False) # Hito 8: Visibility Config
    
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
    file_path = Column(String, nullable=False)  # Local path or URL
    
    is_main = Column(Boolean, default=False)  # Cover image
    order = Column(Integer, default=0)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())


# ============================================================================
# Visits System (@Architect)
# ============================================================================

class VisitWindow(Base):
    """
    Availability block defined by the Seller.
    e.g., "Saturday from 10:00 to 14:00"
    """
    __tablename__ = "visit_windows"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    property = relationship("Property", back_populates="visit_windows")
    
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=False)
    slot_duration_minutes = Column(Integer, default=20, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship to Appointments
    appointments = relationship("VisitAppointment", back_populates="window", cascade="all, delete-orphan")


class VisitAppointment(Base):
    """
    Specific slot booked by a Buyer within a Window.
    """
    __tablename__ = "visit_appointments"

    id = Column(Integer, primary_key=True, index=True)
    window_id = Column(Integer, ForeignKey("visit_windows.id"), nullable=False)
    window = relationship("VisitWindow", back_populates="appointments")
    
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    buyer = relationship("User", back_populates="appointments")
    
    start_time = Column(DateTime(timezone=True), nullable=False)
    status = Column(Enum(VisitStatus), default=VisitStatus.REQUESTED, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class PropertyOffer(Base):
    """
    Formal offer made by a Buyer for a Property.
    Transparent: Seller sees Amount + Buyer Identity + Conditions.
    """
    __tablename__ = "offers"
    
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    # Removing backref here to avoid conflict if defined elsewhere or redefining relationships
    # Using simple foreign keys for now, backrefs defined in Property/User if needed or transparently here
    # Actually, let's keep it simple and clean.
    
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    amount = Column(Float, nullable=False) 
    conditions = Column(Text, nullable=True)
    status = Column(Enum(OfferStatus), default=OfferStatus.PENDING, nullable=False)
    
    
    valid_until = Column(DateTime(timezone=True))
    is_chat_enabled = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # History & Chat
    history = relationship("OfferHistory", backref="offer", cascade="all, delete-orphan")
    messages = relationship("OfferMessage", backref="offer", cascade="all, delete-orphan")


class OfferHistory(Base):
    """
    Audit log for negotiation steps (The 'Legal' truth).
    """
    __tablename__ = "offer_history"
    
    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=False)
    
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String, nullable=False) # MAKE, COUNTER, ACCEPT, REJECT
    amount = Column(Float, nullable=True) # Snapshot of amount at that time
    
    timestamp = Column(DateTime(timezone=True), server_default=func.now())


class OfferMessage(Base):
    """
    Encrypted chat messages between Buyer and Seller for a specific offer.
    """
    __tablename__ = "offer_messages"
    
    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=False)
    
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message_encrypted = Column(String, nullable=False) # Fernet encrypted content
    
    timestamp = Column(DateTime(timezone=True), server_default=func.now())


class Reservation(Base):
    """
    Hito 8: Property Reservation / Deposit.
    prevents double-booking via constraints.
    """
    __tablename__ = "reservations"
    
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Optional link to the Offer that originated this, if any
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=True)
    
    amount = Column(Float, nullable=False)
    status = Column(String, default="pending") # pending, paid, failed, refunded
    
    # Security: Idempotency & Audit
    idempotency_key = Column(String, unique=True, index=True, nullable=False)
    payment_id = Column(String, nullable=True) # Transaction ID from Payment Provider
    
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
    
    # Security: Encrypted Content (Blob) or Path
    file_path = Column(String, nullable=False) # Path to encrypted file
    is_encrypted = Column(Boolean, default=True) 
    
    # Compliance
    status = Column(String, default="pending") # pending, verified, rejected
    extracted_metadata = Column(Text, nullable=True) # JSON with OCR results
    
    uploaded_at = Column(DateTime(timezone=True), server_default=func.now())
