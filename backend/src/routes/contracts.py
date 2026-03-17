
from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session
from fastapi.responses import StreamingResponse
from backend.src.config.database import get_db
from backend.src.models.users import User
from backend.src.routes.auth import get_current_user
from backend.src.models.offers import PropertyOffer, OfferStatus
from backend.src.models.properties import Property
from backend.src.services.contract_service import ContractGenerator
from datetime import datetime, timedelta, timezone
import io
import json
import os
from fastapi import File, UploadFile, Form
from backend.src.schemas.contracts import ContractDetailsUpdate, ContractDetailsResponse, ContractAnalysisResponse
from backend.src.models.offers import ContractAnalysis
from backend.src.services.ai_contract_service import ContractAnalyzer

router = APIRouter()

@router.put("/offers/{offer_id}/details", response_model=ContractDetailsResponse)
def update_contract_details(
    offer_id: int,
    details: ContractDetailsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Updates the legal details for the contract questionnaire.
    Only Buyer or Seller can update.
    """
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    # Security: Only Buyer/Seller
    is_buyer = offer.buyer_id == current_user.id
    prop = db.query(Property).filter(Property.id == offer.property_id).first()
    header_owner = prop.owner_id == current_user.id # Assuming property loaded relation or query
    
    if not (is_buyer or header_owner):
         raise HTTPException(status_code=403, detail="Not authorized")

    # Update Data
    # Store as dict/json
    offer.contract_data = details.model_dump()
    db.commit()
    db.refresh(offer)
    return offer.contract_data

@router.get("/offers/{offer_id}/details", response_model=ContractDetailsResponse)
def get_contract_details(
    offer_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    prop = db.query(Property).filter(Property.id == offer.property_id).first()
    
    if not (offer.buyer_id == current_user.id or prop.owner_id == current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
        
    if not offer.contract_data:
        return ContractDetailsResponse() # Return defaults
        
    return offer.contract_data

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
        limit_date=limit_date,
        contract_data=offer.contract_data or {}
    )
    
    # 5. Return Stream
    return StreamingResponse(
        io.BytesIO(pdf_bytes), 
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=arras_draft_{offer_id}.pdf"}
    )

@router.post("/offers/{offer_id}/upload", response_model=ContractAnalysisResponse)
async def upload_custom_contract(
    offer_id: int,
    file: UploadFile = File(...),
    accept_ai_processing: bool = Form(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Hito 12.6: Upload Custom Contract + AI Analysis.
    - Security: Analyzes MIME type.
    - Liability: Requires accept_ai_processing=True.
    """
    # 1. Fetch Offer
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
        
    prop = db.query(Property).filter(Property.id == offer.property_id).first()
    
    # 2. Authorization
    is_buyer = offer.buyer_id == current_user.id
    is_seller = prop.owner_id == current_user.id
    
    if not (is_buyer or is_seller):
         raise HTTPException(status_code=403, detail="Not authorized")

    # 3. Liability Check
    if not accept_ai_processing:
        # If user refuses AI, we might still save the file but NOT analyze it?
        # User requirement seemed to link upload with analysis option.
        # Let's reject if analysis is requested but not accepted? 
        # API says "upload", but returns "ContractAnalysisResponse".
        # If user just wants to upload without AI, we should allow it but return empty analysis.
        # But for now, let's enforce consent if they want the feature.
        # If accept_ai_processing is False, we just save.
        pass
    
    # 4. Security Scan
    await ContractAnalyzer.validate_file(file)
    
    # 5. Save to PostgreSQL as BYTEA — no filesystem writes
    file_bytes = await file.read()
    offer.custom_contract_data = file_bytes
    offer.custom_contract_content_type = file.content_type or "application/octet-stream"
    offer.custom_contract_filename = file.filename
    offer.custom_contract_path = None
    # Reset previous acceptances — new contract requires fresh approval from both parties
    offer.buyer_contract_accepted_at = None
    offer.seller_contract_accepted_at = None
    
    # 6. AI Analysis (if consented)
    if accept_ai_processing:
        # Mock Text Extraction (In real world: PDF OCR)
        # For simulation, we assume content based on filename or dummy
        simulated_text = f"Contrato de {file.filename}. Cláusula 1: El vendedor entrega..." * 50
        
        role_label = "BUYER" if is_buyer else "SELLER"
        
        analysis_result = await ContractAnalyzer.analyze_text(simulated_text, role_label)
        
        # Save to DB
        db_analysis = ContractAnalysis(
            offer_id=offer.id,
            analysis_json=json.dumps(analysis_result),
            role=role_label,
            cost=analysis_result["cost_estimate"],
            consent_timestamp=datetime.now(),
            disclaimer_version=ContractAnalyzer.DISCLAIMER_VERSION
        )
        
        # Remove old analysis if any?
        # db.query(ContractAnalysis).filter(ContractAnalysis.offer_id == offer_id).delete()
        # Better: Update or create.
        existing = db.query(ContractAnalysis).filter(ContractAnalysis.offer_id == offer_id).first()
        if existing:
            db.delete(existing)
            
        db.add(db_analysis)
        db.commit()
        db.refresh(offer)
        
        return ContractAnalysisResponse(**analysis_result)
    
    db.commit()
    # Return empty analysis if not processed
    return ContractAnalysisResponse(
        risk_score=0, summary="File uploaded. AI Analysis not requested.",
        red_flags=[], green_lights=[], missing_clauses=[], cost_estimate=0.0,
        disclaimer=""
    )


def _get_offer_with_rbac(offer_id: int, current_user: User, db: Session) -> tuple[PropertyOffer, Property]:
    """Fetch offer + property and verify the caller is buyer or seller."""
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    prop = db.query(Property).filter(Property.id == offer.property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
    is_buyer = offer.buyer_id == current_user.id
    is_seller = prop.owner_id == current_user.id
    if not (is_buyer or is_seller):
        raise HTTPException(status_code=403, detail="Not authorized")
    return offer, prop


@router.get("/offers/{offer_id}/contract/download")
def download_contract(
    offer_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Download the custom contract uploaded for this offer.
    Accessible by both buyer and seller.
    Falls back to filesystem path for legacy rows.
    """
    offer, _ = _get_offer_with_rbac(offer_id, current_user, db)

    if offer.custom_contract_data:
        return Response(
            content=offer.custom_contract_data,
            media_type=offer.custom_contract_content_type or "application/octet-stream",
            headers={
                "Content-Disposition": f'attachment; filename="{offer.custom_contract_filename or f"contract_{offer_id}.pdf"}"',
                "Cache-Control": "private, no-store",
            },
        )

    # Legacy fallback
    path = offer.custom_contract_path
    if path and os.path.exists(path):
        from fastapi.responses import FileResponse
        return FileResponse(path=path, filename=os.path.basename(path), media_type="application/octet-stream")

    raise HTTPException(status_code=404, detail="No contract uploaded for this offer")


@router.post("/offers/{offer_id}/contract/accept", status_code=200)
def accept_contract(
    offer_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Buyer or Seller confirms acceptance of the uploaded contract.
    Records the timestamp for the calling party.
    """
    offer, prop = _get_offer_with_rbac(offer_id, current_user, db)

    if not offer.custom_contract_data and not offer.custom_contract_path:
        raise HTTPException(status_code=400, detail="No contract uploaded yet for this offer")

    is_buyer = offer.buyer_id == current_user.id
    now = datetime.now(timezone.utc)

    if is_buyer:
        offer.buyer_contract_accepted_at = now
    else:
        offer.seller_contract_accepted_at = now

    db.commit()

    both_accepted = offer.buyer_contract_accepted_at and offer.seller_contract_accepted_at
    return {
        "accepted_by": "buyer" if is_buyer else "seller",
        "accepted_at": now.isoformat(),
        "both_accepted": bool(both_accepted),
    }


@router.get("/offers/{offer_id}/contract/acceptance")
def get_contract_acceptance(
    offer_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns the acceptance status of both parties for the contract.
    """
    offer, _ = _get_offer_with_rbac(offer_id, current_user, db)
    return {
        "has_contract": bool(offer.custom_contract_data or offer.custom_contract_path),
        "filename": offer.custom_contract_filename,
        "buyer_accepted_at": offer.buyer_contract_accepted_at.isoformat() if offer.buyer_contract_accepted_at else None,
        "seller_accepted_at": offer.seller_contract_accepted_at.isoformat() if offer.seller_contract_accepted_at else None,
        "both_accepted": bool(offer.buyer_contract_accepted_at and offer.seller_contract_accepted_at),
    }
