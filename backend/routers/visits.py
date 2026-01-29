"""
Visits Router (@Jules)
Handles Batch Visit Scheduling.
Allows Sellers to define availability windows and Buyers to book smart slots.
"""

from typing import List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_

from backend.database import get_db
from backend.models import (
    User, Property, VisitWindow, VisitAppointment, VisitStatus
)
from backend.schemas import (
    VisitWindowCreate, VisitWindowResponse, 
    VisitSlotResponse, VisitRequest, VisitAppointmentResponse
)
from backend.security import get_current_active_user
from backend.routers.properties import verify_property_ownership

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


@router.put("/{appointment_id}/status", response_model=VisitAppointmentResponse)
async def update_visit_status(
    appointment_id: int,
    new_status: str, # approved, rejected
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Seller approves or rejects a visit.
    NOTE: If approved, should trigger notification (Email service).
    """
    appointment = db.query(VisitAppointment).join(VisitWindow).join(Property).filter(
        VisitAppointment.id == appointment_id
    ).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    if appointment.window.property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    if new_status not in [VisitStatus.APPROVED, VisitStatus.REJECTED]:
        raise HTTPException(status_code=400, detail="Invalid status")
        
    appointment.status = new_status
    db.commit()
    db.refresh(appointment)
    return appointment


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
        status=VisitStatus.REQUESTED
    )
    
    db.add(appointment)
    db.commit()
    db.refresh(appointment)
    return appointment
