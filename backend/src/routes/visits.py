"""
Visits Router (@Jules)
Handles Batch Visit Scheduling.
Allows Sellers to define availability windows and Buyers to book smart slots.
"""

from typing import List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_

from backend.src.config.database import get_db
from backend.src.models import (
    User, Property, VisitWindow, VisitAppointment, VisitStatus
)
from backend.src.schemas.base import (
    VisitWindowCreate, VisitWindowResponse,
    VisitSlotResponse, VisitRequest, VisitAppointmentResponse
)
from backend.src.utils.security import get_current_active_user
from backend.src.routes.properties import verify_property_ownership
from backend.src.services.email_service import send_visit_request_email

router = APIRouter(prefix="/visits", tags=["Visits"])


# ============================================================================
# Logic & Algorithms
# ============================================================================

def calculate_slots(window: VisitWindow, existing_appointments: List[VisitAppointment]) -> List[VisitSlotResponse]:
    """
    Divides a window into slots of `slot_duration_minutes`.
    Checks against existing appointments to mark availability.
    """
    slots = []
    current_time = window.start_time.replace(tzinfo=None) # Simplify TZ handling for calc
    end_time = window.end_time.replace(tzinfo=None)
    
    # Normalize appointment times
    booked_times = {
        appt.start_time.replace(tzinfo=None) 
        for appt in existing_appointments 
        if appt.status != VisitStatus.REJECTED
    }
    
    while current_time + timedelta(minutes=window.slot_duration_minutes) <= end_time:
        slot_end = current_time + timedelta(minutes=window.slot_duration_minutes)
        
        is_taken = current_time in booked_times
        
        # Add TZ info back if needed, or assume UTC from DB
        # For response, we keep it transparent
        
        slots.append(VisitSlotResponse(
            start_time=current_time, # Pydantic will serialize to ISO
            end_time=slot_end,
            is_available=not is_taken,
            window_id=window.id
        ))
        
        current_time = slot_end
        
    return slots


# ============================================================================
# Seller Endpoints
# ============================================================================

@router.post("/windows", response_model=VisitWindowResponse, status_code=status.HTTP_201_CREATED)
async def create_visit_window(
    window_data: VisitWindowCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Seller defines a time block for batch visits.
    """
    # 1. Verify ownership of property
    verify_property_ownership(db, window_data.property_id, current_user.id)
    
    # 2. Check for overlaps (Basic check)
    overlap = db.query(VisitWindow).filter(
        VisitWindow.property_id == window_data.property_id,
        and_(
            VisitWindow.start_time < window_data.end_time,
            VisitWindow.end_time > window_data.start_time
        )
    ).first()
    
    if overlap:
         raise HTTPException(status_code=400, detail="Time window overlaps with an existing one")

    # 3. Create Window
    new_window = VisitWindow(
        property_id=window_data.property_id,
        start_time=window_data.start_time,
        end_time=window_data.end_time,
        slot_duration_minutes=window_data.slot_duration_minutes
    )
    
    db.add(new_window)
    db.commit()
    db.refresh(new_window)
    return new_window


@router.get("/me/requests", response_model=List[VisitAppointmentResponse])
async def list_visit_requests(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Seller sees all pending requests for their properties.
    """
    # Join Window -> Property -> Owner
    requests = db.query(VisitAppointment).join(VisitWindow).join(Property).filter(
        Property.owner_id == current_user.id
    ).order_by(VisitAppointment.created_at.desc()).all()
    
    return requests


class StatusUpdate(BaseModel):
    status: str


@router.patch("/{appointment_id}/status", response_model=VisitAppointmentResponse)
async def update_visit_status(
    appointment_id: int,
    body: StatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Update visit status with Security & State Machine Enforcement.
    
    Transitions:
    - REQUESTED -> APPROVED/REJECTED (Seller)
    - REQUESTED/APPROVED -> CANCELLED (Buyer/Seller)
    - APPROVED -> COMPLETED/NO_SHOW (Seller ONLY)
    """
    appointment = db.query(VisitAppointment).join(VisitWindow).join(Property).filter(
        VisitAppointment.id == appointment_id
    ).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    is_seller = appointment.window.property.owner_id == current_user.id
    is_buyer = appointment.buyer_id == current_user.id
    
    if not (is_seller or is_buyer):
        raise HTTPException(status_code=403, detail="Not authorized")

    current_status = appointment.status
    new_status = body.status

    # 1. State Machine Logic
    # ----------------------------------------------------------------

    # CANCELLED (Universal)
    if new_status == VisitStatus.CANCELLED:
        if current_status in [VisitStatus.COMPLETED, VisitStatus.NO_SHOW, VisitStatus.REJECTED]:
             raise HTTPException(status_code=400, detail="Cannot cancel finalized visit")
        # Proceed

    # SELLER ACTIONS
    elif is_seller:
        if new_status in [VisitStatus.APPROVED, VisitStatus.REJECTED]:
            if current_status != VisitStatus.REQUESTED:
                raise HTTPException(status_code=400, detail=f"Cannot change from {current_status} to {new_status}")

        elif new_status in [VisitStatus.COMPLETED, VisitStatus.NO_SHOW]:
            if current_status != VisitStatus.APPROVED:
                raise HTTPException(status_code=400, detail="Visit must be APPROVED before completion")
        else:
             raise HTTPException(status_code=400, detail="Invalid status for Seller")

    # BUYER ACTIONS
    elif is_buyer:
        if new_status == VisitStatus.CANCELLED:
             pass # Allowed checks done above
        else:
            raise HTTPException(status_code=403, detail="Buyer can only CANCEL visits")

    # 2. Update
    appointment.status = new_status
    db.commit()
    db.refresh(appointment)
    return appointment


@router.get("/agenda", response_model=List[VisitAppointmentResponse])
async def get_visit_agenda(
    role: str = "seller", # seller / buyer
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Dashboard Agenda: List visits based on role.
    """
    query = db.query(VisitAppointment).join(VisitWindow).join(Property)
    
    if role == "seller":
        query = query.filter(Property.owner_id == current_user.id)
    elif role == "buyer":
        query = query.filter(VisitAppointment.buyer_id == current_user.id)
    else:
        raise HTTPException(status_code=400, detail="Invalid role")
        
    if status_filter:
        query = query.filter(VisitAppointment.status == status_filter)
        
    return query.order_by(VisitAppointment.start_time.asc()).all()


# ============================================================================
# Chat-based Visit Endpoint
# ============================================================================

class ChatVisitResponse(BaseModel):
    offer_id: int
    property_id: int
    property_title: str
    status: str   # 'requested' | 'approved'
    date: Optional[str]
    role: str     # 'buyer' | 'seller'

    class Config:
        from_attributes = True


@router.get("/chat", response_model=List[ChatVisitResponse])
async def get_chat_visits(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Returns visit appointments derived from chat action messages (visit_request /
    visit_accepted) for the current user.  Works regardless of whether the
    OfferResponse serializer has computed visit_status.
    """
    from backend.src.models import PropertyOffer, OfferMessage

    # Collect all offer IDs where this user is buyer or seller
    buyer_offers = (
        db.query(PropertyOffer)
        .filter(PropertyOffer.buyer_id == current_user.id)
        .all()
    )
    owned_prop_ids = (
        db.query(Property.id)
        .filter(Property.owner_id == current_user.id)
        .subquery()
    )
    seller_offers = (
        db.query(PropertyOffer)
        .filter(PropertyOffer.property_id.in_(owned_prop_ids))
        .all()
    )

    offer_map: dict = {o.id: o for o in buyer_offers + seller_offers}
    if not offer_map:
        return []

    # Find all visit-related action messages for those offers
    visit_msgs = (
        db.query(OfferMessage)
        .filter(
            OfferMessage.offer_id.in_(offer_map.keys()),
            OfferMessage.message_type == "action",
        )
        .order_by(OfferMessage.timestamp.asc())
        .all()
    )

    # Track the latest visit state per offer (later messages override earlier)
    offer_visits: dict = {}
    for msg in visit_msgs:
        ad = msg.action_data or {}
        act = ad.get("action_type", "")
        if act not in ("visit_request", "visit_accepted", "visit_rejected", "visit_cancelled"):
            continue
        if msg.offer_id not in offer_visits:
            offer_visits[msg.offer_id] = {"status": None, "date": None}
        if act == "visit_request":
            offer_visits[msg.offer_id]["status"] = "requested"
            offer_visits[msg.offer_id]["date"] = ad.get("date")
        elif act == "visit_accepted":
            offer_visits[msg.offer_id]["status"] = "approved"
            offer_visits[msg.offer_id]["date"] = ad.get("date")
        elif act in ("visit_rejected", "visit_cancelled"):
            offer_visits[msg.offer_id]["status"] = "rejected"
            offer_visits[msg.offer_id]["date"] = None

    results = []
    for offer_id, visit_data in offer_visits.items():
        if visit_data["status"] not in ("requested", "approved"):
            continue
        offer = offer_map[offer_id]
        prop = db.query(Property).filter(Property.id == offer.property_id).first()
        results.append(
            ChatVisitResponse(
                offer_id=offer_id,
                property_id=offer.property_id,
                property_title=prop.title if prop else "Propiedad",
                status=visit_data["status"],
                date=visit_data["date"],
                role="buyer" if offer.buyer_id == current_user.id else "seller",
            )
        )
    return results


# ============================================================================
# Buyer Endpoints
# ============================================================================

@router.get("/properties/{property_id}/slots", response_model=List[VisitSlotResponse])
async def get_available_slots(
    property_id: int,
    db: Session = Depends(get_db)
):
    """
    Calculates dynamic slots for a property based on windows + bookings.
    """
    # 1. Get all future windows
    windows = db.query(VisitWindow).filter(
        VisitWindow.property_id == property_id,
        VisitWindow.end_time > datetime.utcnow()
    ).all()
    
    all_slots = []
    
    for window in windows:
        # Get appointments for this window
        appointments = db.query(VisitAppointment).filter(
            VisitAppointment.window_id == window.id
        ).all()
        
        # Run Algorithm
        slots = calculate_slots(window, appointments)
        all_slots.extend(slots)
        
    return all_slots


@router.post("/book", response_model=VisitAppointmentResponse, status_code=status.HTTP_201_CREATED)
async def book_visit_slot(
    request: VisitRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Buyer reserves a specific slot.
    """
    # 1. Validate Window
    window = db.query(VisitWindow).filter(VisitWindow.id == request.window_id).first()
    if not window:
        raise HTTPException(status_code=404, detail="Visit window not found")

    # 2. Validate Slot Alignment (Anti-Hack check)
    # Ensure start_time matches a valid slot start
    # Simplified: check if start_time is between window start/end

    # 3. Check availability (Race Condition Safety needed for Production, simple check for MVP)
    existing = db.query(VisitAppointment).filter(
        VisitAppointment.window_id == window.id,
        VisitAppointment.start_time == request.start_time,
        VisitAppointment.status != VisitStatus.REJECTED
    ).first()

    if existing:
        raise HTTPException(status_code=409, detail="Slot already booked")

    # 4. Create Appointment
    appointment = VisitAppointment(
        window_id=window.id,
        buyer_id=current_user.id,
        start_time=request.start_time,
        status=VisitStatus.REQUESTED,
        # Filtering Answers
        q_solvency=request.q_solvency,
        q_timeline=request.q_timeline,
        q_maturity=request.q_maturity
    )

    db.add(appointment)
    db.commit()
    db.refresh(appointment)
    return appointment


# ============================================================================
# Visit Request by Email (no slots available fallback)
# ============================================================================

class VisitRequestByEmail(BaseModel):
    property_id: int
    message: str = Field("", max_length=500)


class VisitRequestByEmailResponse(BaseModel):
    status: str
    detail: str


@router.post(
    "/request-email",
    response_model=VisitRequestByEmailResponse,
    status_code=status.HTTP_200_OK,
)
async def request_visit_by_email(
    body: VisitRequestByEmail,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Buyer requests a visit via email when the seller has no availability windows.
    Sends a notification email to the property owner asking them to set up
    visit times.
    """
    # 1. Validate property exists
    prop = db.query(Property).filter(Property.id == body.property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")

    # 2. Prevent seller from emailing themselves
    if prop.owner_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot request a visit on your own property")

    # 3. Fetch owner details
    owner = db.query(User).filter(User.id == prop.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Property owner not found")

    # 4. Send email
    sent = await send_visit_request_email(
        seller_email=owner.email,
        seller_name=owner.full_name,
        buyer_name=current_user.full_name,
        property_title=prop.title or "Sin titulo",
        buyer_message=body.message,
    )

    if not sent:
        raise HTTPException(
            status_code=502,
            detail="No se pudo enviar el email. Intentalo mas tarde.",
        )

    return VisitRequestByEmailResponse(
        status="sent",
        detail="Solicitud de visita enviada al vendedor por email.",
    )
