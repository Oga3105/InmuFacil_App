from sqlalchemy import Column, Integer, String, DECIMAL, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
import enum

class ValuationProvider(str, enum.Enum):
    INTERNAL_ALGO = "InmuFacil_Algorithm"
    EXTERNAL_MOCK = "External_Mock"

class PropertyValuation(Base):
    """Model to store property valuations."""
    __tablename__ = "property_valuations"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id", ondelete="CASCADE"), nullable=False)

    valuation_date = Column(DateTime(timezone=True), server_default=func.now())
    estimated_value = Column(DECIMAL(12, 2), nullable=False)
    currency = Column(String, default="EUR")

    confidence_score = Column(Integer, nullable=False)
    provider = Column(Enum(ValuationProvider, native_enum=False), default=ValuationProvider.INTERNAL_ALGO)

    report_path = Column(String, nullable=True)

    property = relationship("Property", back_populates="valuations")
