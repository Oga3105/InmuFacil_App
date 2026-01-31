
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.responses import StreamingResponse
from backend.src.config.database import get_db
from backend.src.models.users import User
from backend.src.routes.auth import get_current_user
from backend.src.models.offers import PropertyOffer, OfferStatus
from backend.src.models.properties import Property
from backend.src.services.contract_service import ContractGenerator
from datetime import datetime, timedelta
import io

router = APIRouter()

@router.get("/arras/draft/{offer_id}", response_class=StreamingResponse)
def download_arras_draft(
    offer_id: int, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Downloads a draft of the 'Arras Penitenciales' contract.
    Security:
    - User must be authenticated.
    - User must be the BUYER or SELLER of the offer.
    - Offer must be in ACCEPTED status.
    """
    
    # 1. Fetch Offer
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    # 2. Security Checks (@Shield)
    prop = db.query(Property).filter(Property.id == offer.property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
        
    is_buyer = offer.buyer_id == current_user.id
    is_seller = prop.owner_id == current_user.id
    
    if not (is_buyer or is_seller):
        raise HTTPException(status_code=403, detail="Not authorized to view this contract")

    if offer.status != OfferStatus.ACCEPTED:
         raise HTTPException(status_code=400, detail="Contract available only for ACCEPTED offers")

    # 3. Fetch Full Data
    buyer = offer.buyer
    seller = prop.owner
    
    # 4. Generate PDF (@Architect + @Jules)
    # Default limit date: 60 days from now (Mock logic)
    limit_date = datetime.now() + timedelta(days=60)
    
    pdf_bytes = ContractGenerator.generate_arras_draft(
        buyer_name=buyer.full_name or "Comprador Pendiente",
        buyer_dni="12345678X", # TODO: Unmask DNI from KYC
        seller_name=seller.full_name or "Vendedor Pendiente",
        seller_dni="87654321Z", # TODO: Unmask DNI from KYC
        property_address=prop.location,
        property_registry_ref="98765432101234", # Mock Ref
        price_total=float(offer.amount),
        deposit_amount=float(offer.amount * 0.10), # 10% Arras
        limit_date=limit_date
    )
    
    # 5. Return Stream
    return StreamingResponse(
        io.BytesIO(pdf_bytes), 
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=arras_draft_{offer_id}.pdf"}
    )
