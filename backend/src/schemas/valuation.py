from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from backend.src.models.valuation import ValuationProvider

class ValuationRequest(BaseModel):
    """
    Request to trigger a new valuation.
    Usually empty as it uses existing property data, but allows forcing a provider.
    """
    provider: ValuationProvider = ValuationProvider.INTERNAL_ALGO

class ValuationResponse(BaseModel):
    """
    Response with valuation details.
    """
    id: int
    property_id: int
    valuation_date: datetime
    estimated_value: float
    currency: str
    confidence_score: int
    provider: ValuationProvider
    report_path: Optional[str] = None
    
    # Calculated range for UI display
    value_range_min: float
    value_range_max: float
    
    class Config:
        from_attributes = True
