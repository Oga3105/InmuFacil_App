from sqlalchemy import Column, Integer, String, Enum, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.types import JSON
from sqlalchemy.sql import func
from .base import Base
import enum

class StepStatus(str, enum.Enum):
    PENDING = "PENDING"
    PARTIALLY_COMPLETED = "PARTIALLY_COMPLETED"
    COMPLETED = "COMPLETED"

class StepRole(str, enum.Enum):
    BUYER = "BUYER"
    SELLER = "SELLER"
    BOTH = "BOTH"
    SYSTEM = "SYSTEM"

class TransactionStep(Base):
    """Hito 14.5: Granular tracking of the transaction timeline."""
    __tablename__ = "transaction_steps"

    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=False)

    step_order = Column(Integer, nullable=False)
    step_key = Column(String, nullable=False)
    label = Column(String, nullable=False)
    description = Column(String, nullable=True)

    required_role = Column(Enum(StepRole, native_enum=False), default=StepRole.SYSTEM)
    status = Column(Enum(StepStatus, native_enum=False), default=StepStatus.PENDING)

    buyer_confirmed_at = Column(DateTime(timezone=True), nullable=True)
    seller_confirmed_at = Column(DateTime(timezone=True), nullable=True)

    metadata_json = Column(JSON, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    offer = relationship("PropertyOffer", backref="timeline_steps")
