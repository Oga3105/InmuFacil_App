from sqlalchemy.orm import Session
from datetime import datetime
from backend.src.models.offers import PropertyOffer
from backend.src.models.properties import Property
from backend.src.models.enums import PropertyStatus, OfferStatus
from backend.src.models.timeline import TransactionStep, StepStatus
from fastapi import HTTPException
import logging

logger = logging.getLogger("inmufacil.closing")

class ClosingService:
    
    @staticmethod
    def validate_closing_eligibility(db: Session, offer_id: int) -> bool:
        """
        Verify that all transaction steps are completed.
        """
        # 1. Get steps
        steps = db.query(TransactionStep).filter(
            TransactionStep.offer_id == offer_id
        ).all()
        
        if not steps:
            # If no timeline, cannot close securely (Hito 14.5 is required)
            raise HTTPException(400, "Transaction Timeline not initialized")
            
        # 2. Check all completed
        pending_steps = [s for s in steps if s.status != StepStatus.COMPLETED]
        if pending_steps:
             logger.warning(f"[CLOSING] Attempt to close offer {offer_id} with pending steps: {[s.step_key for s in pending_steps]}")
             return False
             
        return True

    @staticmethod
    def execute_closing(db: Session, offer_id: int):
        """
        Finalize the transaction:
        1. Validate Eligibility
        2. Set Property -> SOLD
        3. Set Offer -> COMPLETED
        4. Reject other offers
        """
        logger.info(f"[CLOSING] Executing closing for Offer {offer_id}")
        
        # 1. Validate
        if not ClosingService.validate_closing_eligibility(db, offer_id):
            raise HTTPException(400, "Cannot close transaction: Pending steps in Timeline")
            
        offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
        if not offer:
            raise HTTPException(404, "Offer not found")
            
        property_obj = db.query(Property).filter(Property.id == offer.property_id).first()
        
        # 2. Update Property
        property_obj.status = PropertyStatus.SOLD
        property_obj.updated_at = datetime.utcnow()
        
        # 3. Update Offer
        offer.status = OfferStatus.COMPLETED
        
        # 4. Reject others
        other_offers = db.query(PropertyOffer).filter(
            PropertyOffer.property_id == offer.property_id,
            PropertyOffer.id != offer_id,
            PropertyOffer.status != OfferStatus.REJECTED
        ).all()
        
        for other in other_offers:
            other.status = OfferStatus.REJECTED
            # Optional: Add rejection reason "Property Sold"
            
        db.commit()
        db.refresh(offer)
        db.refresh(property_obj)
        
        logger.info(f"[CLOSING] SUCCESS. Property {property_obj.id} marked as SOLD. Offer {offer.id} COMPLETED.")
        return offer
