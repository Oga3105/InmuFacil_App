"""
Offers Router (@Jules)
Handles the lifecycle of Property Offers (Manifestación de Interés).
"""

from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from pydantic import BaseModel, condecimal, ConfigDict

from backend.src.config.database import get_db
from backend.src.models import User, Property, PropertyOffer, OfferStatus, OfferHistory, OfferMessage
from backend.src.utils.security import get_current_active_user
from backend.src.utils.crypto import encrypt_data, decrypt_data

router = APIRouter(prefix="/offers", tags=["Offers"])

# ============================================================================
# Schemas (Internal for now, can move to schemas.py refactor)
# ============================================================================

class OfferCreate(BaseModel):
    property_id: int
    amount: float # In production use Decimal
    conditions: Optional[str] = None
    valid_days: int = 7

class PropertySnippet(BaseModel):
    id: int
    title: str
    price: float
    seller_name: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

class BuyerSnippet(BaseModel):
    id: int
    full_name: Optional[str] = None
    photo_url: Optional[str] = None
    is_verified: bool = False
    model_config = ConfigDict(from_attributes=True)

class OfferResponse(BaseModel):
    id: int
    property_id: int
    buyer_id: int
    amount: float
    conditions: Optional[str] = None
    status: str
    valid_until: Optional[datetime] = None
    created_at: datetime
    property: Optional[PropertySnippet] = None
    buyer: Optional[BuyerSnippet] = None
    model_config = ConfigDict(from_attributes=True)

class OfferCounter(BaseModel):
    amount: float

def _offers_query(db: Session):
    """Return a query for PropertyOffer with eager-loaded property (+ owner) and buyer."""
    return db.query(PropertyOffer).options(
        joinedload(PropertyOffer.property).joinedload(Property.owner),
        joinedload(PropertyOffer.buyer),
    )


def _serialize_offer(offer: PropertyOffer) -> OfferResponse:
    prop = offer.property
    buyer = offer.buyer
    prop_snippet = None
    if prop:
        prop_snippet = PropertySnippet(
            id=prop.id,
            title=prop.title,
            price=float(prop.price),
            seller_name=prop.owner.full_name if prop.owner else None,
        )
    buyer_snippet = None
    if buyer:
        from backend.src.models.enums import DNIStatus
        buyer_snippet = BuyerSnippet(
            id=buyer.id,
            full_name=buyer.full_name,
            photo_url=buyer.profile_photo_url,
            is_verified=buyer.dni_status == DNIStatus.VALIDADO,
        )
    return OfferResponse(
        id=offer.id,
        property_id=offer.property_id,
        buyer_id=offer.buyer_id,
        amount=float(offer.amount),
        conditions=offer.conditions,
        status=offer.status.value if hasattr(offer.status, 'value') else str(offer.status),
        valid_until=offer.valid_until,
        created_at=offer.created_at,
        property=prop_snippet,
        buyer=buyer_snippet,
    )


class ChatMessageCreate(BaseModel):
    message: str

class ChatMessageResponse(BaseModel):
    id: int
    sender_id: int
    message: str # Decrypted
    timestamp: datetime
    
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
    # Re-fetch with eager loads so the response includes nested property and buyer
    created = _offers_query(db).filter(PropertyOffer.id == offer.id).first()
    return _serialize_offer(created)


@router.get("/me/sent", response_model=List[OfferResponse])
async def list_sent_offers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Buyer sees offers they made.
    """
    offers = _offers_query(db).filter(
        PropertyOffer.buyer_id == current_user.id
    ).all()
    return [_serialize_offer(o) for o in offers]


@router.get("/me/received", response_model=List[OfferResponse])
async def list_received_offers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Seller sees offers for their properties.
    """
    # Use subquery to avoid conflicting JOIN with joinedload on the same table
    owned_ids = db.query(Property.id).filter(Property.owner_id == current_user.id).subquery()
    offers = _offers_query(db).filter(PropertyOffer.property_id.in_(owned_ids)).all()
    return [_serialize_offer(o) for o in offers]


@router.post("/{offer_id}/counter", response_model=OfferResponse)
async def counter_offer(
    offer_id: int,
    counter_data: OfferCounter,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Seller sends a counter-offer.
    Updates Offer Status and logs History.
    """
    offer = db.query(PropertyOffer).join(Property).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    # Verify Owner
    if offer.property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only owner can counter")
        
    if offer.status not in [OfferStatus.PENDING, OfferStatus.COUNTERED]:
        raise HTTPException(status_code=400, detail="Cannot counter a closed offer")

    # Update Logic
    offer.status = OfferStatus.COUNTERED
    offer.amount = counter_data.amount
    
    # Log History
    history = OfferHistory(
        offer_id=offer.id,
        actor_id=current_user.id,
        action="COUNTER",
        amount=counter_data.amount
    )
    db.add(history)
    db.commit()
    db.refresh(offer)
    return offer


@router.post("/{offer_id}/accept", response_model=OfferResponse)
async def accept_offer(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Accept an offer or counter-offer.
    Triggers the Transaction Timeline (Hito 14.5).
    """
    offer = db.query(PropertyOffer).join(Property).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    is_owner = offer.property.owner_id == current_user.id
    is_buyer = offer.buyer_id == current_user.id
    
    # Logic: 
    # If Status is PENDING, only Owner can accept.
    # If Status is COUNTERED (by Owner), Buyer can accept.
    
    if offer.status == OfferStatus.PENDING:
        if not is_owner:
             raise HTTPException(status_code=403, detail="Only owner can accept a pending offer")
    elif offer.status == OfferStatus.COUNTERED:
         if not is_buyer:
              raise HTTPException(status_code=403, detail="Only buyer can accept a counter-offer")
    else:
         raise HTTPException(status_code=400, detail="Cannot accept an offer in this state")

    # Update Status
    offer.status = OfferStatus.ACCEPTED
    
    # Log History
    history = OfferHistory(
        offer_id=offer.id,
        actor_id=current_user.id,
        action="ACCEPT",
        amount=offer.amount
    )
    db.add(history)
    
    # Hook: Initialize Timeline (Hito 14.5)
    from backend.src.services.timeline_service import TimelineService
    timeline_service = TimelineService(db)
    timeline_service.initialize_timeline(offer)
    
    db.commit()
    db.refresh(offer)
    return offer


@router.post("/{offer_id}/chat/enable", status_code=status.HTTP_200_OK)
async def enable_chat(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Seller enables chat for this offer.
    """
    offer = db.query(PropertyOffer).join(Property).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    if offer.property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only owner can enable chat")
        
    offer.is_chat_enabled = True
    db.commit()
    return {"status": "chat_enabled"}


@router.post("/{offer_id}/chat", response_model=ChatMessageResponse)
async def send_chat_message(
    offer_id: int,
    msg_data: ChatMessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Send encrypted message.
    """
    offer = db.query(PropertyOffer).join(Property).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    
    # Access Control: Sender must be Buyer or Owner
    is_owner = offer.property.owner_id == current_user.id
    is_buyer = offer.buyer_id == current_user.id
    
    if not (is_owner or is_buyer):
         raise HTTPException(status_code=403, detail="Not authorized")
         
    # Logic: Chat Enabled?
    if not offer.is_chat_enabled:
        # Auto-enable if Owner speaks first? Let's stick to explicit enable for MVP as per plan
        if is_owner:
             pass # Owner override? No, strict to plan: Enable first.
        raise HTTPException(status_code=403, detail="Chat is disabled by seller")

    # Encrypt
    encrypted_text = encrypt_data(msg_data.message)
    
    msg = OfferMessage(
        offer_id=offer.id,
        sender_id=current_user.id,
        message_encrypted=encrypted_text
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    
    # Return decrypted for response (it's the sender, they know what they sent)
    return ChatMessageResponse(
        id=msg.id,
        sender_id=msg.sender_id,
        message=msg_data.message,
        timestamp=msg.timestamp
    )


@router.get("/{offer_id}/chat", response_model=List[ChatMessageResponse])
async def get_chat_history(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Get and decrypt chat history.
    """
    offer = db.query(PropertyOffer).join(Property).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    # Access Control
    is_owner = offer.property.owner_id == current_user.id
    is_buyer = offer.buyer_id == current_user.id
    
    if not (is_owner or is_buyer):
         raise HTTPException(status_code=403, detail="Not authorized")
         
    messages = db.query(OfferMessage).filter(OfferMessage.offer_id == offer.id).order_by(OfferMessage.timestamp.asc()).all()
    
    response = []
    for m in messages:
        try:
            plaintext = decrypt_data(m.message_encrypted)
        except:
            plaintext = "[Error Decrypting]"
            
        response.append(ChatMessageResponse(
            id=m.id,
            sender_id=m.sender_id,
            message=plaintext,
            timestamp=m.timestamp
        ))
        
    return response


@router.get("/{offer_id}/closing-certificate", status_code=status.HTTP_200_OK)
async def get_closing_certificate(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Hito 15: Retrieve Closing Certificate for a Completed Transaction.
    """
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    # Access: Buyer, Seller (via Property), or Admin
    prop = db.query(Property).filter(Property.id == offer.property_id).first()
    is_buyer = offer.buyer_id == current_user.id
    is_seller = prop.owner_id == current_user.id
    
    if not (is_buyer or is_seller):
         raise HTTPException(status_code=403, detail="Not authorized")
         
    if offer.status != OfferStatus.COMPLETED:
        raise HTTPException(status_code=404, detail="Transaction not closed yet")
        
    return {
        "certificate_id": f"CERT-{offer.id}-{int(datetime.utcnow().timestamp())}",
        "property_id": prop.id,
        "offer_id": offer.id,
        "status": "OFFICIALLY_SOLD",
        "closing_date": datetime.utcnow(), # Ideally from the 'sold' timestamp in Property or Timeline
        "buyer_id": offer.buyer_id, # Masked in UI
        "owner_id": prop.owner_id,
        "final_price": offer.amount,
        "legal_note": "This transaction has been verified and closed securely via InmuFácil."
    }
