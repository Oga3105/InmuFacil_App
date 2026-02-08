from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, UploadFile
from typing import Optional, Dict

from backend.src.models.handover import PropertyHandover
from backend.src.models.offers import PropertyOffer, OfferStatus
from backend.src.models.users import User, UserType
from backend.src.services.document_service import DocumentService # Reuse encryption logic

class HandoverService:
    """
    Hito 16 Part B: Post-Sales Handover Service.
    Manages the 'Digital Vault' for utility credentials and bills.
    """

    @staticmethod
    def get_handover(db: Session, offer_id: int, user: User) -> PropertyHandover:
        """
        Retrieve handover dossier.
        Security: Only SELLER (owner), BUYER (winner), or ADMIN can view.
        """
        handover = db.query(PropertyHandover).filter(PropertyHandover.offer_id == offer_id).first()
        if not handover:
            raise HTTPException(status_code=404, detail="Handover dossier not initialized")
            
        # Security Check
        offer = handover.offer 
        is_buyer = (offer.buyer_id == user.id)
        is_seller = (offer.property.owner_id == user.id)
        is_admin = (user.email == "admin@inmufacil.com")
        
        if not (is_buyer or is_seller or is_admin):
            raise HTTPException(status_code=403, detail="Not authorized to view this handover")
            
        return handover

    @staticmethod
    def upsert_handover_data(db: Session, offer_id: int, user: User, data: Dict) -> PropertyHandover:
        """
        Create or Update utility credentials (CUPS, etc).
        Security: Only SELLER can update this data.
        """
        # 1. Validate Offer & Permissions
        offer = db.query(PropertyOffer).get(offer_id)
        if not offer:
            raise HTTPException(status_code=404, detail="Offer not found")
            
        if offer.property.owner_id != user.id:
            raise HTTPException(status_code=403, detail="Only the Seller can update handover info")
            
        # 2. Check current status
        # Handover data should be prepared usually after Arras or Closing.
        # Strict: Allow updates if Offer is >= SIGNED
        if offer.status not in [OfferStatus.SIGNED, OfferStatus.COMPLETED]:
             raise HTTPException(status_code=400, detail="Offer is not in a valid state for handover (Must be SIGNED or COMPLETED)")

        # 3. Upsert
        handover = db.query(PropertyHandover).filter(PropertyHandover.offer_id == offer_id).first()
        if not handover:
            handover = PropertyHandover(offer_id=offer_id)
            db.add(handover)
        
        # Update fields
        for key, value in data.items():
            if hasattr(handover, key):
                setattr(handover, key, value)
                
        db.commit()
        db.refresh(handover)
        return handover

    @staticmethod
    async def upload_bill(
        db: Session, 
        offer_id: int, 
        user: User, 
        bill_type: str, # 'electricity', 'water', 'gas', 'community', 'ibi'
        file: UploadFile
    ) -> PropertyHandover:
        """
        Secure upload for Utility Bills.
        Uses DocumentService to encrypt and store.
        """
        # Reuse validation logic
        offer = db.query(PropertyOffer).get(offer_id)
        if not offer or offer.property.owner_id != user.id:
             raise HTTPException(status_code=403, detail="Only Seller can upload bills")

        handover = db.query(PropertyHandover).filter(PropertyHandover.offer_id == offer_id).first()
        if not handover:
             # Auto-create if not exists
             handover = PropertyHandover(offer_id=offer_id)
             db.add(handover)
             db.commit()

        # Upload & Encrypt
        # We define a mapping for internal filenames
        prefix = f"handover_{offer_id}_{bill_type}"
        saved_path = await DocumentService.save_protected_document(file, prefix)
        
        # Map input bill_type to Model Field
        field_map = {
            "electricity": "bill_electricity_path",
            "water": "bill_water_path",
            "gas": "bill_gas_path",
            "community": "certificate_community_path",
            "ibi": "receipt_ibi_path"
        }
        
        if bill_type not in field_map:
            raise HTTPException(status_code=400, detail=f"Invalid bill type. Allowed: {list(field_map.keys())}")
            
        target_field = field_map[bill_type]
        setattr(handover, target_field, saved_path)
        
        db.commit()
        db.refresh(handover)
        return handover
