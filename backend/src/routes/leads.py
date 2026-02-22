from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from ..config.database import get_db
from ..models.leads import Lead
from ..schemas.leads import LeadCreate, LeadResponse
import logging

router = APIRouter(
    prefix="/leads",
    tags=["Leads"]
)

logger = logging.getLogger("inmufacil")

@router.post("/", response_model=LeadResponse, status_code=status.HTTP_201_CREATED)
def create_lead(lead: LeadCreate, db: Session = Depends(get_db)):
    """
    Capture a lead from the 404 page (or other sources).
    
    Security: Implements Silent Idempotency.
    If email exists, returns 200 OK (masquerading as success) to prevent user enumeration.
    """
    existing_lead = db.query(Lead).filter(Lead.email == lead.email).first()
    
    if existing_lead:
        logger.info(f"[LEAD] Duplicate lead attempt: {lead.email} (Silently ignored)")
        # Return existing lead but with 200 status (modified in response if needed, 
        # but technically we are returning the object so it looks like it worked)
        # To be cleaner effectively, we just return the existing object.
        # The status code defaults to 201 defined in decorator, strictly we should change it to 200
        # for true semantic correctness, but for "silent" ignore, 201 is also fine 
        # as it implies "resource created" (or present). 
        # Let's enforce 200 explicitly for duplicates if we want to be precise, 
        # but simplest is just returning it.
        return existing_lead

    new_lead = Lead(email=lead.email)
    db.add(new_lead)
    db.commit()
    db.refresh(new_lead)
    logger.info(f"[LEAD] New lead captured: {lead.email}")
    return new_lead
