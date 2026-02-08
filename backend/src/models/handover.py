from sqlalchemy import Column, Integer, String, Float, ForeignKey, JSON, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base

class PropertyHandover(Base):
    """
    Hito 16 Part B: Post-Sales Handover Data.
    Acts as a secure vault for Utility Credentials (CUPS) and Bill Documents.
    Linked to a specific COMPLETED Offer.
    """
    __tablename__ = "property_handover"
    
    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(Integer, ForeignKey("offers.id"), unique=True, nullable=False)
    
    # Utility Identifiers (Credentials)
    electricity_cups = Column(String, nullable=True)
    gas_cups = Column(String, nullable=True)
    water_reference = Column(String, nullable=True)
    
    # Financial Info
    ibi_year_cost = Column(Float, nullable=True) # Annual Property Tax
    community_fee_monthly = Column(Float, nullable=True)
    
    # Contact Info for Admin/President
    community_admin_contact = Column(JSON, nullable=True) # {"name": "...", "phone": "...", "email": "..."}
    
    # Secure Files (Encrypted Paths on Disk)
    bill_electricity_path = Column(String, nullable=True)
    bill_water_path = Column(String, nullable=True)
    bill_gas_path = Column(String, nullable=True)
    certificate_community_path = Column(String, nullable=True) # Certificado Deuda Cero
    receipt_ibi_path = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationship
    offer = relationship("backend.src.models.offers.PropertyOffer", backref="handover")
