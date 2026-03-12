"""
Offers Router (@Jules)
Handles the lifecycle of Property Offers (Manifestación de Interés).
"""

from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from pydantic import BaseModel, Field, ConfigDict

from backend.src.config.database import get_db
from backend.src.models import User, Property, PropertyOffer, OfferStatus, OfferHistory, OfferMessage, BuyerSolvency
from backend.src.utils.security import get_current_active_user
from backend.src.utils.crypto import encrypt_data, decrypt_data

router = APIRouter(prefix="/offers", tags=["Offers"])

# ============================================================================
# Schemas (Internal for now, can move to schemas.py refactor)
# ============================================================================

class OfferCreate(BaseModel):
    property_id: int
    amount: int = Field(..., gt=0, description="Offer amount in EUR, integers only — no decimals")
    conditions: Optional[str] = None
    valid_days: int = 7

class PropertySnippet(BaseModel):
    id: int
    title: str
    price: int
    seller_name: Optional[str] = None
    seller_photo_url: Optional[str] = None
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
    amount: int
    conditions: Optional[str] = None
    status: str
    valid_until: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    is_chat_enabled: bool = False
    property: Optional[PropertySnippet] = None
    buyer: Optional[BuyerSnippet] = None
    last_message: Optional[str] = None
    unread_count: int = 0
    confirmed_visit_date: Optional[str] = None
    requested_visit_date: Optional[str] = None
    visit_status: Optional[str] = None
    payment_method: Optional[str] = None
    buyer_solvency_submitted: bool = False
    seller_solvency_accepted: bool = False
    second_buyer_pending: bool = False
    model_config = ConfigDict(from_attributes=True)

class OfferCounter(BaseModel):
    amount: int = Field(..., gt=0, description="Counter-offer amount in EUR, integers only — no decimals")

def _offers_query(db: Session):
    """Return a query for PropertyOffer with eager-loaded property (+ owner), buyer, and messages."""
    from sqlalchemy.orm import selectinload
    return db.query(PropertyOffer).options(
        joinedload(PropertyOffer.property).joinedload(Property.owner),
        joinedload(PropertyOffer.buyer),
        selectinload(PropertyOffer.messages),
    )


def _decrypt_message(encrypted: str) -> str:
    """
    Decrypt a chat message trying AES-256-GCM first (crypto.py), then Fernet
    (security.py legacy). Returns a non-empty placeholder if both fail so that
    conversations are never hidden from the inbox due to a decryption error.
    """
    if not encrypted:
        return '...'
    # Primary: AES-256-GCM (current scheme, crypto.py)
    try:
        return decrypt_data(encrypted) or '...'
    except Exception:
        pass
    # Fallback: Fernet (legacy scheme, security.py)
    try:
        from backend.src.utils.security import decrypt_data as _fernet_decrypt
        return _fernet_decrypt(encrypted) or '...'
    except Exception:
        pass
    return '...'


def _serialize_offer(offer: PropertyOffer, db: Session) -> OfferResponse:
    prop = offer.property
    buyer = offer.buyer
    prop_snippet = None
    if prop:
        prop_snippet = PropertySnippet(
            id=prop.id,
            title=prop.title,
            price=int(prop.price),
            seller_name=prop.owner.full_name if prop.owner else None,
            seller_photo_url=prop.owner.profile_photo_url if prop.owner else None,
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
    # Compute last_message preview and updated_at from messages (now eagerly loaded)
    last_message = ''
    updated_at = offer.created_at
    # Include ALL messages regardless of timestamp (null timestamps treated as epoch)
    all_msgs = list(offer.messages) if offer.messages else []
    valid_msgs = all_msgs  # keep full list for visit-date scan below
    if all_msgs:
        last_msg = sorted(
            all_msgs,
            key=lambda m: (m.timestamp is not None, m.timestamp or datetime.min),
        )[-1]
        updated_at = last_msg.timestamp or offer.created_at
        if getattr(last_msg, 'message_type', 'text') == 'action':
            action_type = (getattr(last_msg, 'action_data', None) or {}).get('action_type', 'accion')
            last_message = f'[{action_type}]'
        else:
            last_message = _decrypt_message(last_msg.message_encrypted)

    # Find the most recent visit status and dates from action messages
    confirmed_visit_date = None
    requested_visit_date = None
    visit_status = None
    
    # We want to find the latest state of a visit. Action types can be: 
    # visit_request, visit_accepted, visit_rejected, visit_cancelled
    for m in valid_msgs:
        if getattr(m, 'message_type', 'text') == 'action':
            ad = getattr(m, 'action_data', None) or {}
            act_type = ad.get('action_type')
            
            if act_type == 'visit_request':
                requested_visit_date = ad.get('date')
                # If there's an incoming request, the state becomes "requested" (if not overridden later)
                visit_status = 'requested'
                
            elif act_type == 'visit_accepted':
                # An accepted visit overrides requested 
                confirmed_visit_date = ad.get('date')
                visit_status = 'approved'
                
            elif act_type == 'visit_rejected':
                visit_status = 'rejected'
                
            elif act_type == 'visit_cancelled':
                visit_status = 'cancelled'

    # Compute unread_count: messages sent by the OTHER party that are not yet read.
    # The "other party" from the buyer's perspective is the seller (owner) and vice versa.
    unread_count = 0
    buyer_id = offer.buyer_id
    seller_id = offer.property.owner_id if offer.property else None
    if offer.messages:
        for m in offer.messages:
            if not m.is_read:
                # A message is "unread for the buyer" if it was sent by the seller, and vice versa.
                # Since we don't know which user is calling, count all unread from non-buyer + non-seller
                # sides. For the list view we expose total unread (both sides combined).
                unread_count += 1

    solvency = db.query(BuyerSolvency).filter(BuyerSolvency.buyer_id == offer.buyer_id).first()
    payment_method = solvency.payment_method.value if solvency and solvency.payment_method else None
    buyer_solvency_submitted = solvency is not None
    seller_solvency_accepted = bool(getattr(offer, 'seller_solvency_accepted', False) or False)
    # True when buyer declared joint purchase but second buyer has not yet submitted identity data
    second_buyer_pending = bool(
        solvency and solvency.is_multi_buyer and solvency.second_buyer_verified_at is None
    )

    return OfferResponse(
        id=offer.id,
        property_id=offer.property_id,
        buyer_id=offer.buyer_id,
        amount=int(offer.amount),
        conditions=offer.conditions,
        status=offer.status.value if hasattr(offer.status, 'value') else str(offer.status),
        valid_until=offer.valid_until,
        created_at=offer.created_at,
        updated_at=updated_at,
        is_chat_enabled=bool(offer.is_chat_enabled),
        property=prop_snippet,
        buyer=buyer_snippet,
        last_message=last_message,
        unread_count=unread_count,
        confirmed_visit_date=confirmed_visit_date,
        requested_visit_date=requested_visit_date,
        visit_status=visit_status,
        payment_method=payment_method,
        buyer_solvency_submitted=buyer_solvency_submitted,
        seller_solvency_accepted=seller_solvency_accepted,
        second_buyer_pending=second_buyer_pending,
    )


class ChatMessageCreate(BaseModel):
    message: str

class ChatMessageResponse(BaseModel):
    id: int
    sender_id: int
    message: str  # Decrypted
    message_type: str = "text"
    metadata: Optional[dict] = None
    is_read: bool = False
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

    # 1b. CEE Gate — block offers on EXPOSED properties (missing energy certificate)
    from backend.src.models.enums import PropertyStatus, EnergyCertification
    if prop.status == PropertyStatus.EXPOSED:
        raise HTTPException(
            status_code=400,
            detail="Incluye el CEE para recibir ofertas",
        )
    if prop.legal and prop.legal.energy_certification == EnergyCertification.EN_TRAMITE:
        raise HTTPException(
            status_code=400,
            detail="Incluye el CEE para recibir ofertas",
        )

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
    return _serialize_offer(created, db)


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
    return [_serialize_offer(o, db) for o in offers]


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
    return [_serialize_offer(o, db) for o in offers]


@router.get("/{offer_id}", response_model=OfferResponse)
async def get_offer(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Return a single offer. Caller must be buyer or property owner."""
    offer = _offers_query(db).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    is_buyer = offer.buyer_id == current_user.id
    is_seller = offer.property.owner_id == current_user.id
    if not is_buyer and not is_seller:
        raise HTTPException(status_code=403, detail="Not a participant")
    return _serialize_offer(offer, db)


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

    is_owner = offer.property.owner_id == current_user.id
    is_buyer = offer.buyer_id == current_user.id

    if offer.status == OfferStatus.PENDING:
        if not is_owner:
            raise HTTPException(status_code=403, detail="Only the seller can counter a pending offer")
        new_status = OfferStatus.COUNTER_OFFER
        history_action = "COUNTER"
    elif offer.status == OfferStatus.COUNTER_OFFER:
        if not is_buyer:
            raise HTTPException(status_code=403, detail="Only the buyer can counter a seller counter-offer")
        new_status = OfferStatus.PENDING
        history_action = "BUYER_COUNTER"
    else:
        raise HTTPException(status_code=400, detail="Cannot counter a closed offer")

    offer.status = new_status
    offer.amount = counter_data.amount

    history = OfferHistory(
        offer_id=offer.id,
        actor_id=current_user.id,
        action=history_action,
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
    # If Status is COUNTER_OFFER (by Owner), Buyer can accept.

    if offer.status == OfferStatus.PENDING:
        if not is_owner:
             raise HTTPException(status_code=403, detail="Only owner can accept a pending offer")
    elif offer.status == OfferStatus.COUNTER_OFFER:
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


@router.post("/{offer_id}/withdraw", status_code=status.HTTP_200_OK)
async def withdraw_offer(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Buyer withdraws (cancels) their offer before the arras contract is signed.
    Allowed while status is PENDING, ACCEPTED, or SIGNING_PENDING.
    """
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    if offer.buyer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the buyer can withdraw their offer")

    withdrawable_statuses = {OfferStatus.PENDING, OfferStatus.COUNTER_OFFER, OfferStatus.ACCEPTED, OfferStatus.SIGNING_PENDING}
    if offer.status not in withdrawable_statuses:
        raise HTTPException(status_code=400, detail="Offer cannot be withdrawn at this stage")

    offer.status = OfferStatus.WITHDRAWN
    history = OfferHistory(
        offer_id=offer.id,
        actor_id=current_user.id,
        action="WITHDRAW",
        amount=offer.amount,
    )
    db.add(history)
    db.commit()
    db.refresh(offer)
    return {"message": "Offer withdrawn successfully", "offer_id": offer.id, "status": offer.status}


@router.post("/{offer_id}/reject", status_code=status.HTTP_200_OK)
async def reject_offer(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Seller rejects a pending offer, or buyer rejects a counter-offer.
    Sets status to REJECTED and terminates the negotiation.
    """
    offer = db.query(PropertyOffer).join(Property).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    is_owner = offer.property.owner_id == current_user.id
    is_buyer = offer.buyer_id == current_user.id

    if offer.status == OfferStatus.PENDING:
        if not is_owner:
            raise HTTPException(status_code=403, detail="Only seller can reject a pending offer")
    elif offer.status == OfferStatus.COUNTER_OFFER:
        if not is_buyer:
            raise HTTPException(status_code=403, detail="Only buyer can reject a counter-offer")
    else:
        raise HTTPException(status_code=400, detail="Cannot reject offer in this state")

    offer.status = OfferStatus.REJECTED
    history = OfferHistory(
        offer_id=offer.id,
        actor_id=current_user.id,
        action="REJECT",
        amount=offer.amount,
    )
    db.add(history)
    db.commit()
    return {"message": "Offer rejected", "offer_id": offer.id}


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
        
    is_owner = offer.property.owner_id == current_user.id
    is_buyer = offer.buyer_id == current_user.id
    if not (is_owner or is_buyer):
        raise HTTPException(status_code=403, detail="Not an offer participant")

    offer.is_chat_enabled = True
    db.commit()
    return {"status": "chat_enabled", "offer_id": offer_id}


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

    # Censorship filter — strip phone/email patterns before encryption (@Shield GDPR)
    from backend.src.services.chat_service import CensorshipFilter, manager as _ws_manager
    sanitized_text = CensorshipFilter.sanitize(msg_data.message)

    # Encrypt
    encrypted_text = encrypt_data(sanitized_text)

    msg = OfferMessage(
        offer_id=offer.id,
        sender_id=current_user.id,
        message_encrypted=encrypted_text,
        message_type="text",
        is_read=False,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)

    # Broadcast to WebSocket subscribers in this offer room
    import asyncio
    ws_payload = {
        "event": "message",
        "data": {
            "id": msg.id,
            "sender_id": msg.sender_id,
            "message": sanitized_text,
            "message_type": "text",
            "metadata": None,
            "is_read": False,
            "created_at": msg.timestamp.isoformat() if msg.timestamp else None,
        },
    }
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.ensure_future(_ws_manager.broadcast(offer.id, ws_payload))
    except Exception:
        pass  # WebSocket broadcast is best-effort; REST response is authoritative

    # Return decrypted for response (it's the sender, they know what they sent)
    return ChatMessageResponse(
        id=msg.id,
        sender_id=msg.sender_id,
        message=sanitized_text,
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
        plaintext = _decrypt_message(m.message_encrypted)
        response.append(ChatMessageResponse(
            id=m.id,
            sender_id=m.sender_id,
            message=plaintext,
            message_type=m.message_type if hasattr(m, 'message_type') else "text",
            metadata=m.action_data if hasattr(m, 'action_data') else None,
            is_read=m.is_read if hasattr(m, 'is_read') else False,
            timestamp=m.timestamp,
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
