from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from datetime import datetime

from backend.src.config.database import get_db
from backend.src.routes.auth import get_current_user
from backend.src.models.users import User
from backend.src.models.offers import PropertyOffer
from backend.src.models.enums import OfferStatus
from backend.src.services.signature_service import get_signature_service, SignatureService

router = APIRouter(prefix="/contracts", tags=["Signature"])

@router.post("/{offer_id}/sign/request", status_code=status.HTTP_200_OK)
async def request_signature(
    offer_id: int,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    signature_service: SignatureService = Depends(get_signature_service)
):
    """
    Inicia el proceso de firma digital para una oferta aceptada.
    Solo el Comprador o el Vendedor pueden iniciar esto (actualmente simplificado a quien lo pida).
    """
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    # Validation: Only Buyer or Seller
    # Note: Property is relationship.
    # offer.property might be lazy loaded, ensure eager or check IDs
    is_buyer = offer.buyer_id == current_user.id
    # For Seller check we need property ownership
    # We assume offer.property is loaded or we check DB
    is_seller = False
    if offer.property and offer.property.owner_id == current_user.id:
        is_seller = True
        
    if not (is_buyer or is_seller):
        raise HTTPException(status_code=403, detail="Not authorized to sign this contract")
    
    # State Check: Must be ACCEPTED or COUNTER_OFFER? Usually ACCEPTED.
    # If already SIGNED or SIGNING_PENDING, maybe handle differently?
    if offer.status == OfferStatus.SIGNED:
         raise HTTPException(status_code=400, detail="Contract already signed")
         
    # Generate Token via Service
    # We use a dummy document URL for now
    doc_url = f"http://internal/contracts/{offer_id}.pdf"
    
    try:
        token = await signature_service.initiate_process(
            offer_id=offer.id,
            email=current_user.email,
            name=current_user.full_name,
            document_path=doc_url
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Signature Provider Error: {str(e)}")
    
    # Update DB
    offer.status = OfferStatus.SIGNING_PENDING
    offer.signature_token = token
    db.commit()
    
    return {"message": "Signature request initiated", "token": token, "status": "signing_pending"}


@router.get("/sign/simulate/{token}", status_code=status.HTTP_200_OK)
async def simulate_signing_click(
    token: str,
    db: Session = Depends(get_db),
    signature_service: SignatureService = Depends(get_signature_service)
):
    """
    Endpoint de Simulación (Dev Only).
    Simula que el usuario hizo clic en el enlace del email 'Firmar'.
    Valida el token y cambia el estado a SIGNED.
    """
    # 1. Provide Validation (Mock always returns True if logic is fine)
    # But we should check if token matches any offer in DB first
    offer = db.query(PropertyOffer).filter(PropertyOffer.signature_token == token).first()
    
    if not offer:
        raise HTTPException(status_code=404, detail="Invalid or expired signature token")
    
    # 2. Verify with Provider
    is_valid = await signature_service.provider.verify_signature(token)
    if not is_valid:
        raise HTTPException(status_code=400, detail="Provider rejected signature")
        
    # 3. Mark as Signed
    offer.status = OfferStatus.SIGNED
    offer.signature_token = None # Invalidate token (One-time)
    
    # Set a dummy path for the signed PDF
    offer.signed_contract_path = f"contracts/signed/{offer.id}_{datetime.now().strftime('%Y%m%d')}.pdf"
    
    db.commit()
    
    return {
        "message": "Contract successfully signed", 
        "offer_id": offer.id,
        "new_status": "signed",
        "contract_url": offer.signed_contract_path
    }
