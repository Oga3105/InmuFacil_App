from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, Float, ForeignKey, Text, LargeBinary
from sqlalchemy.orm import relationship
from sqlalchemy.types import JSON
from sqlalchemy.sql import func
from .base import Base
from .enums import OfferStatus

class PropertyOffer(Base):
    """Formal offer made by a Buyer for a Property."""
    __tablename__ = "offers"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    buyer = relationship("User", foreign_keys=[buyer_id])
    property = relationship("Property", foreign_keys=[property_id])

    amount = Column(Float, nullable=False)
    conditions = Column(Text, nullable=True)
    status = Column(Enum(OfferStatus, native_enum=False), default=OfferStatus.PENDING, nullable=False)

    contract_data = Column(JSON, nullable=True)
    custom_contract_path = Column(String, nullable=True)
    custom_contract_data = Column(LargeBinary, nullable=True)
    custom_contract_content_type = Column(String(100), nullable=True)
    custom_contract_filename = Column(String, nullable=True)
    buyer_contract_accepted_at = Column(DateTime(timezone=True), nullable=True)
    seller_contract_accepted_at = Column(DateTime(timezone=True), nullable=True)

    valid_until = Column(DateTime(timezone=True))
    is_chat_enabled = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    seller_solvency_accepted = Column(Boolean, nullable=True)
    seller_solvency_accepted_at = Column(DateTime(timezone=True), nullable=True)

    signature_token = Column(String, unique=True, index=True, nullable=True)
    signed_contract_path = Column(String, nullable=True)

    notary_id = Column(Integer, ForeignKey("notaries.id"), nullable=True)
    notary_appointment_date = Column(DateTime(timezone=True), nullable=True)
    notary_status = Column(String, default="not_assigned")

    notary = relationship("Notary")

    history = relationship("OfferHistory", backref="offer", cascade="all, delete-orphan")
    messages = relationship("OfferMessage", backref="offer", cascade="all, delete-orphan")
    contract_analysis = relationship("ContractAnalysis", backref="offer", uselist=False, cascade="all, delete-orphan")


class ContractAnalysis(Base):
    """Hito 12.6: AI Analysis of Custom Contracts."""
    __tablename__ = "contract_analysis"

    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=False)

    analysis_json = Column(JSON, nullable=True)
    role = Column(String, nullable=False)
    cost = Column(Float, default=0.0)

    consent_timestamp = Column(DateTime(timezone=True), nullable=False)
    disclaimer_version = Column(String, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())


class OfferHistory(Base):
    """Audit log for negotiation steps."""
    __tablename__ = "offer_history"

    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=False)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String, nullable=False)
    amount = Column(Float, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())


class OfferMessage(Base):
    """Encrypted chat messages between Buyer and Seller."""
    __tablename__ = "offer_messages"

    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message_encrypted = Column(String, nullable=False)
    message_type = Column(String, default="text", nullable=False)
    action_data = Column(JSON, nullable=True)
    is_read = Column(Boolean, default=False, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())


class Reservation(Base):
    """Hito 8: Property Reservation / Deposit."""
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=True)
    amount = Column(Float, nullable=False)
    status = Column(String, default="pending")
    idempotency_key = Column(String, unique=True, index=True, nullable=False)
    payment_id = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
