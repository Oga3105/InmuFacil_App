from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from backend.src.models.enums import ServiceType, ServiceStatus

class ServiceOrderBase(BaseModel):
    service_type: ServiceType
    property_id: Optional[int] = None
    offer_id: Optional[int] = None
    
    # Simple notes from requester
    requester_notes: Optional[str] = None

class ServiceOrderCreate(ServiceOrderBase):
    """
    User requests a service.
    """
    pass

class ServiceOrderUpdate(BaseModel):
    """
    Provider updates status or Admin updates details.
    """
    status: Optional[ServiceStatus] = None
    quoted_price: Optional[float] = None
    final_price: Optional[float] = None
    
    # Result payload (e.g. {"valuation": 300000})
    result_data: Optional[Dict[str, Any]] = None
    
    admin_notes: Optional[str] = None
    rating: Optional[int] = Field(None, ge=1, le=5)

class ServiceOrderResponse(ServiceOrderBase):
    id: int
    ticket_number: str
    requester_id: int
    provider_id: Optional[int] = None
    
    status: ServiceStatus
    quoted_price: Optional[float] = None
    final_price: Optional[float] = None
    
    result_data: Optional[Dict[str, Any]] = None
    rating: Optional[int] = None
    
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
