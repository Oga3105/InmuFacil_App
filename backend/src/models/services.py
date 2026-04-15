from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Enum, func
from sqlalchemy.orm import relationship
from sqlalchemy.types import JSON
from .base import Base
from .enums import ServiceType, ServiceStatus

class ServiceOrder(Base):
    """Unified Ticket System for External Services."""
    __tablename__ = "service_orders"

    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String, unique=True, index=True)

    service_type = Column(Enum(ServiceType, native_enum=False), nullable=False)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), nullable=True)

    requester_id = Column(Integer, ForeignKey("users.id"))
    provider_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    status = Column(Enum(ServiceStatus, native_enum=False), default=ServiceStatus.REQUESTED)
    quoted_price = Column(Float, nullable=True)
    final_price = Column(Float, nullable=True)

    result_data = Column(JSON, nullable=True)

    rating = Column(Integer, nullable=True)
    admin_notes = Column(String, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    property = relationship("Property")
    offer = relationship("PropertyOffer")
    requester = relationship("User", foreign_keys=[requester_id])
    provider = relationship("User", foreign_keys=[provider_id])
