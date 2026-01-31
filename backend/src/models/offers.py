from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, Float, ForeignKey, Text
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
