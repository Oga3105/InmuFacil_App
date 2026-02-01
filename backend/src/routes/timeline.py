from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

from backend.src.config.database import get_db
from backend.src.routes.auth import get_current_user
from backend.src.models.users import User
from backend.src.models.offers import PropertyOffer
from backend.src.services.timeline_service import TimelineService
from backend.src.models.timeline import StepStatus, StepRole

router = APIRouter(prefix="/timeline", tags=["Timeline & Transaction Control"])

class TimelineStepResponse(BaseModel):
    id: int
    step_order: int
    step_key: str
    label: str
    description: Optional[str]
    required_role: str
    status: str
    buyer_confirmed_at: Optional[datetime]
    seller_confirmed_at: Optional[datetime]
    
    class Config:
        from_attributes = True

class ConfirmAction(BaseModel):
    notes: Optional[str] = None

@router.get("/{offer_id}", response_model=List[TimelineStepResponse])
def get_timeline(
    offer_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get the transaction timeline.
    Security: Only Buyer or Seller of the offer (or Admin) can view.
    """
    offer = db.query(PropertyOffer).get(offer_id)
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    # RBAC
    if current_user.id not in [offer.buyer_id, offer.property.owner_id] and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized to view this timeline")

    service = TimelineService(db)
    # Ensure initialized (Lazy init if missing)
    steps = service.initialize_timeline(offer)
    return steps

@router.post("/{step_id}/confirm", response_model=TimelineStepResponse)
def confirm_step(
    step_id: int,
    action: ConfirmAction,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Confirm a step (Check the box).
    User role is automatically detected relative to the offer.
    """
    service = TimelineService(db)
    step = db.query(service.db.model_timeline.TransactionStep).get(step_id) if hasattr(service.db, 'model_timeline') else None
    
    # Direct query because service.db is just db session
    from backend.src.models.timeline import TransactionStep
    step = db.query(TransactionStep).get(step_id)
    
    if not step:
        raise HTTPException(status_code=404, detail="Step not found")
    
    offer = step.offer
    
    # Determine Role
    role_requesting = None
    if current_user.id == offer.buyer_id:
        role_requesting = "BUYER"
    elif current_user.id == offer.property.owner_id:
        role_requesting = "SELLER"
    else:
        raise HTTPException(status_code=403, detail="You are not a participant in this transaction")

    try:
        updated_step = service.confirm_step(
            step_id=step_id,
            role_requesting=role_requesting,
            metadata={"user_id": current_user.id, "note": action.notes}
        )
        return updated_step
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
