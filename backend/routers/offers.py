"""
Offers Router (@Jules)
Handles the lifecycle of Property Offers (Manifestación de Interés).
"""

from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, condecimal

from backend.database import get_db
from backend.models import User, Property, PropertyOffer, OfferStatus
from backend.security import get_current_active_user

router = APIRouter(prefix="/offers", tags=["Offers"])

# ============================================================================
# Schemas (Internal for now, can move to schemas.py refactor)
# ============================================================================

class OfferCreate(BaseModel):
    property_id: int
    amount: float # In production use Decimal
    conditions: Optional[str] = None
    valid_days: int = 7

class OfferResponse(BaseModel):
    id: int
    property_id: int
    buyer_id: int
    amount: float
    conditions: Optional[str]
    status: str
    valid_until: Optional[datetime]
    created_at: datetime
    
    class Config:
        from_attributes = True

# ============================================================================
# Endpoints
# ============================================================================

@router.post("/", response_model=OfferResponse, status_code=status.HTTP_201_CREATED)
async def create_offer(
    offer_data: OfferCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Buyer creates a new offer.
    """
    # 1. Validate Property
    prop = db.query(Property).filter(Property.id == offer_data.property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
        
    # 2. Defense in Depth: No Self-Offers
    if prop.owner_id == current_user.id:
        raise HTTPException(status_code=400, detail="Owner cannot bid on own property")
        
    # 3. Validate Amount
    if offer_data.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
        
    # 4. Check active offers (Optional: limit 1 active offer per property per user)
    active_offer = db.query(PropertyOffer).filter(
        PropertyOffer.property_id == offer_data.property_id,
        PropertyOffer.buyer_id == current_user.id,
        PropertyOffer.status == OfferStatus.PENDING
    ).first()
    
    if active_offer:
        raise HTTPException(status_code=409, detail="You already have a pending offer for this property")

    # 5. Create
    from datetime import timedelta
    valid_until = datetime.utcnow() + timedelta(days=offer_data.valid_days)
    
    offer = PropertyOffer(
        property_id=offer_data.property_id,
        buyer_id=current_user.id,
        amount=offer_data.amount,
        conditions=offer_data.conditions,
        valid_until=valid_until,
        status=OfferStatus.PENDING
    )
    
    db.add(offer)
    db.commit()
    db.refresh(offer)
    return offer


@router.get("/me/sent", response_model=List[OfferResponse])
async def list_sent_offers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Buyer sees offers they made.
    """
    return db.query(PropertyOffer).filter(
        PropertyOffer.buyer_id == current_user.id
    ).all()


@router.get("/me/received", response_model=List[OfferResponse])
async def list_received_offers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Seller sees offers for their properties.
    """
    # Join Offer -> Property -> Owner
    return db.query(PropertyOffer).join(Property).filter(
        Property.owner_id == current_user.id
    ).all()
