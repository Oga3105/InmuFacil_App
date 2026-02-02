from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Enum, func
from sqlalchemy.orm import relationship
from sqlalchemy.types import JSON
from .base import Base
from .enums import ServiceType, ServiceStatus

class ServiceOrder(Base):
    """
    Unified Ticket System for External Services.
    Tracks requests to Notaries, Valuers, Photographers, etc.
    """
    __tablename__ = "service_orders"
    
    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String, unique=True, index=True) # e.g. "SRV-2026-0001"
    
    # Context
    service_type = Column(Enum(ServiceType), nullable=False)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=True)
    
    # Actors
    requester_id = Column(Integer, ForeignKey("users.id")) # Who asked?
    provider_id = Column(Integer, ForeignKey("users.id"), nullable=True) # Who does it?
    
    # Status & Finance
    status = Column(Enum(ServiceStatus), default=ServiceStatus.REQUESTED)
    quoted_price = Column(Float, nullable=True)
    final_price = Column(Float, nullable=True)
    
    # Data Payload (Flexible Result)
    # Stores: {"energy_label": "A", "valuation_amount": 300000}
    result_data = Column(JSON, nullable=True)
    
    # Quality Control
    rating = Column(Integer, nullable=True) # 1-5
    admin_notes = Column(String, nullable=True) # Internal feedback
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    property = relationship("Property")
    offer = relationship("PropertyOffer")
    requester = relationship("User", foreign_keys=[requester_id])
    provider = relationship("User", foreign_keys=[provider_id])
