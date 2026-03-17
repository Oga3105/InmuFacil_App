from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, Float, ForeignKey, Text, LargeBinary
from sqlalchemy.orm import relationship
from sqlalchemy.types import JSON
from sqlalchemy.sql import func
from .base import Base
from .enums import OfferStatus

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
    
    # Relationships
    buyer = relationship("User", foreign_keys=[buyer_id])
    property = relationship("Property", foreign_keys=[property_id])
    
    amount = Column(Float, nullable=False) 
    conditions = Column(Text, nullable=True)
    status = Column(Enum(OfferStatus), default=OfferStatus.PENDING, nullable=False)
    
    
    contract_data = Column(JSON, nullable=True) # Refinement Hito 12.5
    custom_contract_path = Column(String, nullable=True)       # deprecated — kept for legacy rows
    custom_contract_data = Column(LargeBinary, nullable=True)  # BYTEA storage (replaces path)
    custom_contract_content_type = Column(String(100), nullable=True)
    custom_contract_filename = Column(String, nullable=True)
    # Contract acceptance — both parties must explicitly accept before timeline advances
    buyer_contract_accepted_at = Column(DateTime(timezone=True), nullable=True)
    seller_contract_accepted_at = Column(DateTime(timezone=True), nullable=True)
    
    
    valid_until = Column(DateTime(timezone=True))
    is_chat_enabled = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Fase 2: Seller solvency acceptance — seller must review buyer passport before timeline advances
    seller_solvency_accepted = Column(Boolean, nullable=True)
    seller_solvency_accepted_at = Column(DateTime(timezone=True), nullable=True)

    # Hito 13: Digital Signature
    signature_token = Column(String, unique=True, index=True, nullable=True) # One-time token
    signed_contract_path = Column(String, nullable=True) # Path to final signed PDF
    
    # Hito 14: Notary Integration
    notary_id = Column(Integer, ForeignKey("notaries.id"), nullable=True)
    notary_appointment_date = Column(DateTime(timezone=True), nullable=True)
    notary_status = Column(Enum("not_assigned", "assigned", "dossier_sent", "completed", name="notarystatus"), default="not_assigned")
    
    # Relationships
    notary = relationship("Notary")
    
    # History & Chat
    history = relationship("OfferHistory", backref="offer", cascade="all, delete-orphan")
    messages = relationship("OfferMessage", backref="offer", cascade="all, delete-orphan")
    contract_analysis = relationship("ContractAnalysis", backref="offer", uselist=False, cascade="all, delete-orphan") # 1:1 usually? Or 1:N? User asked "cualquiera de las dos partes". Both can analyze? Then 1:N.
    # Logic: Buyer uploads, Seller uploads? If 1 offer has only 1 active contract, maybe 1:1 is enough for the "latest".
    # But if "cualquiera de las dos partes", maybe duplicate analysis?
    # Let's assume 1:N but typically 1.

class ContractAnalysis(Base):
    """
    Hito 12.6: AI Analysis of Custom Contracts.
    Includes Liability Waivers.
    """
    __tablename__ = "contract_analysis"
    
    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=False)
    
    analysis_json = Column(JSON, nullable=True)
    role = Column(String, nullable=False) # BUYER or SELLER
    cost = Column(Float, default=0.0)
    
    # Legal / Liability
    consent_timestamp = Column(DateTime(timezone=True), nullable=False) 
    disclaimer_version = Column(String, nullable=False) # e.g. "v1.0"
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())



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
    message_type: 'text' | 'action' (offer proposal, visit request, etc.)
    metadata: JSON payload for action messages, e.g. {action_type, amount, date}
    is_read: False until the recipient opens the conversation.
    """
    __tablename__ = "offer_messages"

    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=False)

    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message_encrypted = Column(String, nullable=False)  # Fernet encrypted content

    message_type = Column(String, default="text", nullable=False)  # 'text' | 'action'
    action_data = Column(JSON, nullable=True)  # {action_type, amount, date, ...}
    is_read = Column(Boolean, default=False, nullable=False)

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
