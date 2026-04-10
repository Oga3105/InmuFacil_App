"""
Properties Router
Handles CRUD operations for real estate listings with Advanced Data Intelligence.
@Jules: Implementation of Seller/Owner features.
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Response
from sqlalchemy.orm import Session, joinedload
from backend.src.config.database import get_db, engine
from backend.src.models import (
    Property, User, PropertyFeatures, PropertyLegal, 
    PropertyFinancial, PropertyEnvironment, PropertyMedia, MediaType,
    Reservation, PropertyStatus, PropertyType, OperationType, # Hito 8 + Search
    PropertyDocument, DocumentType, PropertyValuation # Hito 9 + Valuation
)
from backend.src.schemas.base import PropertyCreate, PropertyDraftCreate, StatusUpdate, PropertyResponse, PropertyMediaResponse, PropertyMediaCreate
from backend.src.schemas.valuation import ValuationRequest, ValuationResponse
from backend.src.services.valuation_service import ValuationService
from backend.src.utils.security import get_current_active_user
from backend.src.services.image_service import validate_image, process_image_to_bytes
from backend.src.services.payment_service import MockPaymentProvider
from backend.src.services.document_service import process_document, get_decrypted_document, get_decrypted_document_from_path, ComplianceError
from pydantic import BaseModel
from typing import Optional
from sqlalchemy import or_

# Ensure tables exist (fail-safe for new satellites)
# Base.metadata.create_all(bind=engine)

router = APIRouter(prefix="/properties", tags=["Properties"])


# ============================================================================
# Helpers
# ============================================================================

class ReservationRequest(BaseModel):
    token: str # Payment Token (e.g. "tok_visa")
    idempotency_key: str
    amount: float # Should match backend expectation, but useful for validation

def calculate_metrics(property_model: Property):
    """
    Auto-calculate financial metrics based on available data.
    """
    # Price per m2
    if property_model.price and property_model.surface_area > 0:
        if not property_model.financial:
             property_model.financial = PropertyFinancial(property_id=property_model.id)
        property_model.financial.price_m2 = round(property_model.price / property_model.surface_area, 2)
        
    # Gross Yield
    if property_model.financial and property_model.financial.estimated_rent_monthly and property_model.price > 0:
        annual_rent = property_model.financial.estimated_rent_monthly * 12
        property_model.financial.gross_yield = round((annual_rent / property_model.price) * 100, 2)

def verify_property_ownership(db: Session, property_id: int, user_id: int) -> Property:
    property = db.query(Property).filter(Property.id == property_id).first()
    if not property:
        raise HTTPException(status_code=404, detail="Property not found")
    if property.owner_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    return property

# ============================================================================
# Public Endpoints
# ============================================================================

@router.get("", response_model=List[PropertyResponse])
async def list_properties(
    skip: int = 0, 
    limit: int = 100, 
    q: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    property_type: Optional[PropertyType] = None,
    operation_type: Optional[OperationType] = None,
    # Features
    min_surface: Optional[float] = None,
    bedrooms: Optional[int] = None,
    has_elevator: Optional[bool] = None,
    has_pool: Optional[bool] = None,
    has_terrace: Optional[bool] = None,
    has_garage: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    """
    List properties with Advanced Filtering (Dynamic Query Builder).
    Supports: Price Range, Text Search, Type, and Features (Pool, etc).
    """
    # 1. Start Query with Joins for Satellites (Left Join for filtering)
    query = db.query(Property).outerjoin(PropertyFeatures).options(
        joinedload(Property.features),
        joinedload(Property.legal),
        joinedload(Property.financial),
        joinedload(Property.environment),
        joinedload(Property.media),
        joinedload(Property.owner)
    )
    
    # 2. Logic: Visibility (Hito 8)
    query = query.filter(
        (Property.status == PropertyStatus.PUBLISHED) | 
        ((Property.status == PropertyStatus.RESERVED) & (Property.hide_when_reserved == False))
    )
    
    # 3. Dynamic Filters
    
    # Text Search (Title or Location)
    if q:
        search = f"%{q}%"
        query = query.filter(
            or_(
                Property.title.ilike(search),
                Property.location.ilike(search)
            )
        )
        
    # Price
    if min_price is not None:
        query = query.filter(Property.price >= min_price)
    if max_price is not None:
        query = query.filter(Property.price <= max_price)
        
    # Types
    if property_type:
        query = query.filter(Property.property_type == property_type)
    if operation_type:
        query = query.filter(Property.operation_type == operation_type)
        
    # Surface
    if min_surface:
        query = query.filter(Property.surface_area >= min_surface)
        
    # Features (Require Join with PropertyFeatures)
    if bedrooms:
        query = query.filter(PropertyFeatures.bedrooms >= bedrooms)
        
    # Boolean Features
    # Note: If record is NULL (no features), it counts as False
    if has_pool:
        query = query.filter(PropertyFeatures.has_pool == True)
        
    if has_terrace:
        query = query.filter(PropertyFeatures.has_terrace == True)
        
    if has_garage:
        query = query.filter(PropertyFeatures.has_garage == True)
        
    if has_elevator:
        query = query.filter(PropertyFeatures.has_elevator == True)

    # 4. Execute
    properties = query.offset(skip).limit(limit).all()
    return properties


@router.get("/{property_id}", response_model=PropertyResponse)
async def get_property(
    property_id: int, 
    db: Session = Depends(get_db)
):
    """
    Get specific property details with all intelligence data.
    """
    property = db.query(Property).options(
        joinedload(Property.features),
        joinedload(Property.legal),
        joinedload(Property.financial),
        joinedload(Property.environment),
        joinedload(Property.media),
        joinedload(Property.owner)
    ).filter(Property.id == property_id).first()
    
    if not property:
        raise HTTPException(status_code=404, detail="Property not found")
    return property


# ============================================================================
# Seller Endpoints (Authenticated)
# ============================================================================

@router.post("/", response_model=PropertyResponse, status_code=status.HTTP_201_CREATED)
async def create_property(
    property_data: PropertyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Create a new property listing with optional advanced data.
    """
    # 1. Create Core Property
    core_data = property_data.model_dump(exclude={'features', 'legal', 'financial'})
    # Auto-compute location string from structured fields if not provided
    if not core_data.get('location') and core_data.get('street'):
        parts = [p for p in [core_data.get('street'), core_data.get('street_number'),
                              core_data.get('city'), core_data.get('postal_code')] if p]
        core_data['location'] = ', '.join(parts) or 'Sin dirección'
    if not core_data.get('location'):
        core_data['location'] = 'Sin dirección'
    new_property = Property(
        **core_data,
        owner_id=current_user.id
    )
    db.add(new_property)
    db.flush()  # Generate ID for satellites
    
    # 2. Create Satellites if provided
    if property_data.features:
        features = PropertyFeatures(**property_data.features.model_dump(), property_id=new_property.id)
        db.add(features)
        
    if property_data.legal:
        legal = PropertyLegal(**property_data.legal.model_dump(), property_id=new_property.id)
        db.add(legal)
        
    if property_data.financial:
        financial = PropertyFinancial(**property_data.financial.model_dump(), property_id=new_property.id)
        db.add(financial)
        
    # Calculate Metrics
    calculate_metrics(new_property)

    db.commit()
    # Re-query with eager joins — SQLAlchemy 2.0 expires all attributes after
    # commit; returning the bare instance causes Pydantic to lazy-load every
    # relationship during serialization, which fails on an expired session object.
    new_property = (
        db.query(Property)
        .options(
            joinedload(Property.features),
            joinedload(Property.legal),
            joinedload(Property.financial),
            joinedload(Property.environment),
            joinedload(Property.media),
            joinedload(Property.owner),
        )
        .filter(Property.id == new_property.id)
        .first()
    )
    return new_property


@router.get("/me/all", response_model=List[PropertyResponse])
async def list_my_properties(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    List ALL my properties (Seller Panel) — includes drafts and unpublished.
    """
    return db.query(Property).options(
        joinedload(Property.features),
        joinedload(Property.legal),
        joinedload(Property.financial),
        joinedload(Property.media),
        joinedload(Property.owner)
    ).filter(Property.owner_id == current_user.id).all()


@router.post("/draft", response_model=PropertyResponse, status_code=status.HTTP_201_CREATED)
async def create_draft_property(
    draft_data: PropertyDraftCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Save a partial listing as draft. All fields optional except status.
    """
    core_data = draft_data.model_dump(exclude={'features'}, exclude_none=True)
    # Auto-compute location string from structured fields if not provided
    if not core_data.get('location') and core_data.get('street'):
        parts = [p for p in [core_data.get('street'), core_data.get('street_number'),
                              core_data.get('city'), core_data.get('postal_code')] if p]
        core_data['location'] = ', '.join(parts)
    # Ensure required DB fields have fallback values
    core_data.setdefault('title', '')
    core_data.setdefault('price', 0.0)
    core_data.setdefault('surface_area', 0.0)
    core_data.setdefault('location', '')
    core_data.setdefault('property_type', 'piso')
    core_data.setdefault('operation_type', 'venta')
    new_property = Property(**core_data, owner_id=current_user.id)
    db.add(new_property)
    db.flush()
    if draft_data.features:
        features = PropertyFeatures(**draft_data.features.model_dump(), property_id=new_property.id)
        db.add(features)
    db.commit()
    # Re-query with eager joins — same pattern as PATCH /status.
    # SQLAlchemy 2.0 expires all attributes after commit; returning the bare
    # instance would force Pydantic to lazy-load every relationship during
    # serialization, which fails on an expired session object.
    new_property = (
        db.query(Property)
        .options(
            joinedload(Property.features),
            joinedload(Property.legal),
            joinedload(Property.financial),
            joinedload(Property.environment),
            joinedload(Property.media),
            joinedload(Property.owner),
        )
        .filter(Property.id == new_property.id)
        .first()
    )
    return new_property


@router.patch("/{property_id}/status", response_model=PropertyResponse)
async def update_property_status(
    property_id: int,
    body: StatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Change status of a property: draft -> published -> unpublished.
    """
    prop = verify_property_ownership(db, property_id, current_user.id)
    prop.status = PropertyStatus(body.status)
    db.commit()
    # Re-query with all eager joins — PropertyResponse serializes features,
    # legal, financial, environment and media; omitting any of them causes a
    # lazy-load attempt on an expired SQLAlchemy 2.0 session → 500.
    prop = (
        db.query(Property)
        .options(
            joinedload(Property.features),
            joinedload(Property.legal),
            joinedload(Property.financial),
            joinedload(Property.environment),
            joinedload(Property.media),
            joinedload(Property.owner),
        )
        .filter(Property.id == property_id)
        .first()
    )
    return prop


@router.patch("/{property_id}/allow-visits", response_model=PropertyResponse)
async def toggle_allow_visits(
    property_id: int,
    body: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Toggle allow_visits flag for a property owned by the current user."""
    prop = verify_property_ownership(db, property_id, current_user.id)
    prop.allow_visits = bool(body.get("allow_visits", prop.allow_visits))
    db.commit()
    db.refresh(prop)
    return prop


@router.put("/{property_id}", response_model=PropertyResponse)
async def update_property(
    property_id: int,
    property_update: PropertyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Update a property listing and its satellite data.
    """
    property = verify_property_ownership(db, property_id, current_user.id)
    
    # Update Core
    core_data = property_update.model_dump(exclude={'features', 'legal', 'financial'}, exclude_unset=True)
    # Auto-compute location string from structured fields if not provided
    if not core_data.get('location') and core_data.get('street'):
        parts = [p for p in [core_data.get('street'), core_data.get('street_number'),
                              core_data.get('city'), core_data.get('postal_code')] if p]
        core_data['location'] = ', '.join(parts) or 'Sin dirección'
    from datetime import datetime, timezone as _tz
    for key, value in core_data.items():
        setattr(property, key, value)

    # Stamp consent date when seller enables AI comfort consent for the first time
    if core_data.get('ai_comfort_consent') is True and not property.ai_comfort_consent_date:
        property.ai_comfort_consent_date = datetime.now(_tz.utc)

    # Update Satellites (Create if not exists, Update if exists)
    
    # Features
    if property_update.features:
        if not property.features:
            property.features = PropertyFeatures(property_id=property.id)
        for key, value in property_update.features.model_dump(exclude_unset=True).items():
            setattr(property.features, key, value)

    # Legal
    if property_update.legal:
        if not property.legal:
            property.legal = PropertyLegal(property_id=property.id)
        for key, value in property_update.legal.model_dump(exclude_unset=True).items():
            setattr(property.legal, key, value)
            
    # Financial
    if property_update.financial:
        if not property.financial:
            property.financial = PropertyFinancial(property_id=property.id)
        for key, value in property_update.financial.model_dump(exclude_unset=True).items():
            setattr(property.financial, key, value)
            
    # Recalculate Metrics
    calculate_metrics(property)
        
    db.commit()
    db.refresh(property)
    return property


@router.delete("/{property_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_property(
    property_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Delete a property listing.
    """
    property = verify_property_ownership(db, property_id, current_user.id)
    db.delete(property)
    db.commit()
    return None


# ============================================================================
# Media Endpoints
# ============================================================================

@router.post("/{property_id}/media/upload", response_model=List[PropertyMediaResponse])
async def upload_property_images(
    property_id: int,
    files: List[UploadFile] = File(...),
    is_main: bool = Form(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Upload multiple images for a property.
    Validates, resizes, optimizes, and saves to disk.
    """
    property = verify_property_ownership(db, property_id, current_user.id)
    uploaded_media = []
    
    # If is_main is True, unset others first (only applies if we want one of the batch to be main, logic might need tweak)
    # For bulk upload, 'is_main' usually applies to the first one or none, or frontend sets it later.
    # We will assume if is_main is passed, it applies to the FIRST image effectively, or resets.
    # To be safe: if many files are uploaded and is_main=True, only the first one gets it? 
    # Or frontend sends one by one with is_main?
    # Better approach: Accept logic, if is_main, reset all previous. Then, assign is_main to the first of this batch?
    
    if is_main:
        db.query(PropertyMedia).filter(
            PropertyMedia.property_id == property.id
        ).update({"is_main": False})
    
    for i, file in enumerate(files):
        # Validation & Processing called for each file
        # Note: validate_image reads file, ensure pointer resets or use file.spool_max_size
        validate_image(file)
        img_bytes, content_type = process_image_to_bytes(file)

        # Only the first image of the batch gets is_main if user requested it
        current_is_main = is_main if i == 0 else False

        # Create DB Entry — binary stored in file_data, no filesystem path
        new_media = PropertyMedia(
            property_id=property.id,
            media_type=MediaType.IMAGE,
            file_data=img_bytes,
            content_type=content_type,
            file_path=None,
            is_main=current_is_main,
            order=0
        )
        db.add(new_media)
        uploaded_media.append(new_media)
        
    db.commit()
    for media in uploaded_media:
        db.refresh(media)
        
    return uploaded_media


@router.post("/{property_id}/media/link", response_model=PropertyMediaResponse)
async def add_property_media_link(
    property_id: int,
    media_data: PropertyMediaCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Add a video link (YouTube/Vimeo) or Virtual Tour.
    """
    property = verify_property_ownership(db, property_id, current_user.id)
    
    if media_data.media_type == MediaType.IMAGE:
         raise HTTPException(status_code=400, detail="Use /upload endpoint for images")
         
    new_media = PropertyMedia(
        property_id=property.id,
        media_type=media_data.media_type,
        file_path=media_data.file_path,
        is_main=media_data.is_main,
        order=media_data.order
    )
    
    db.add(new_media)
    db.commit()
    db.commit()
    db.refresh(new_media)
    return new_media

# ============================================================================
# Valuation Endpoints (Hito 10)
# ============================================================================

@router.post("/{property_id}/valuation", response_model=ValuationResponse)
async def request_valuation(
    property_id: int,
    request: ValuationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Request a new property valuation (Tasación).
    Only the owner can request this.
    """
    verify_property_ownership(db, property_id, current_user.id)
    
    try:
        valuation = ValuationService.calculate_valuation(
            db, property_id, request.provider
        )
        
        # Calculate ranges for display (e.g. +/- 10%)
        val_float = float(valuation.estimated_value)
        return ValuationResponse(
            id=valuation.id,
            property_id=valuation.property_id,
            valuation_date=valuation.valuation_date,
            estimated_value=val_float,
            currency=valuation.currency,
            confidence_score=valuation.confidence_score,
            provider=valuation.provider,
            report_path=valuation.report_path,
            value_range_min=val_float * 0.9,
            value_range_max=val_float * 1.1
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/{property_id}/valuation", response_model=List[ValuationResponse])
async def get_valuation_history(
    property_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Get valuation history for a property.
    Only the owner can view this sensitive financial data.
    """
    verify_property_ownership(db, property_id, current_user.id)
    
    valuations = ValuationService.get_valuation_history(db, property_id)
    
    # Map to schema (adding calculated ranges)
    results = []
    for v in valuations:
        val_float = float(v.estimated_value)
        results.append(ValuationResponse(
            id=v.id,
            property_id=v.property_id,
            valuation_date=v.valuation_date,
            estimated_value=val_float,
            currency=v.currency,
            confidence_score=v.confidence_score,
            provider=v.provider,
            report_path=v.report_path,
            value_range_min=val_float * 0.9,
            value_range_max=val_float * 1.1
        ))
    
    return results

@router.get("/media/{media_id}/file")
async def get_media_file(media_id: int, db: Session = Depends(get_db)):
    """Serve image binary stored as BYTEA in PostgreSQL."""
    media = db.query(PropertyMedia).filter(PropertyMedia.id == media_id).first()
    if not media or not media.file_data:
        raise HTTPException(status_code=404, detail="Media not found")
    return Response(
        content=media.file_data,
        media_type=media.content_type or "image/jpeg",
        headers={"Cache-Control": "public, max-age=86400"},
    )


@router.delete("/media/{media_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_media(
    media_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Delete a media asset.
    """
    media = db.query(PropertyMedia).join(Property).filter(PropertyMedia.id == media_id).first()
    
    if not media:
        raise HTTPException(status_code=404, detail="Media not found")
        
    if media.property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    # If file is local, delete it
    # TODO: Implement secure delete (checking if path is safe) in image_service
        
    db.delete(media)
    db.commit()
    return None


@router.post("/{property_id}/reserve", status_code=status.HTTP_200_OK)
async def reserve_property(
    property_id: int,
    res_data: ReservationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Hito 8: Process Deposit & Reserve Property.
    Uses Idempotency & Locking (Simulated) to prevent double booking.
    """
    # 1. Idempotency Check
    existing_res = db.query(Reservation).filter(
        Reservation.idempotency_key == res_data.idempotency_key
    ).first()
    
    if existing_res:
         # Return the result of the previous attempt
         if existing_res.status == "paid":
             return {"status": "success", "tx_id": existing_res.payment_id, "message": "Already reserved"}
         else:
             raise HTTPException(status_code=400, detail="Previous attempt failed")

    # 2. Lock & Check Status
    # In SQLite, with_for_update() doesn't do much, but the logic stands.
    property = db.query(Property).filter(Property.id == property_id).first()
    
    if not property:
        raise HTTPException(status_code=404, detail="Property not found")
        
    if property.status == PropertyStatus.RESERVED:
        raise HTTPException(status_code=409, detail="Property is already reserved")
        
    if property.status != PropertyStatus.PUBLISHED:
        raise HTTPException(status_code=400, detail="Property not available for reservation")
        
    # 3. Process Payment (Mock)
    # Validate amount? ideally comes from Property.price * 0.01 or fixed.
    # We blindly trust client for MVP but normally backend sets amount.
    
    try:
        success, tx_id, error = MockPaymentProvider.process_payment(
            res_data.amount, res_data.token, res_data.idempotency_key
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
    if not success:
         raise HTTPException(status_code=402, detail=f"Payment Failed: {error}")
         
    # 4. Update State (ACID)
    try:
        property.status = PropertyStatus.RESERVED
        
        new_res = Reservation(
            property_id=property.id,
            buyer_id=current_user.id,
            amount=res_data.amount,
            status="paid",
            idempotency_key=res_data.idempotency_key,
            payment_id=tx_id
        )
        db.add(new_res)
        db.commit()
        
        return {"status": "success", "tx_id": tx_id}
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Transaction verification failed")


# ============================================================================
# Hito 9: Compliance & Documents
# ============================================================================

@router.post("/{property_id}/documents", status_code=status.HTTP_201_CREATED)
async def upload_document(
    property_id: int,
    doc_type: DocumentType = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Secure Upload of Legal Documents (Nota Simple, etc).
    Encrypts content at rest and performs OCR for validation.
    """
    property = verify_property_ownership(db, property_id, current_user.id)
    
    try:
        # Use Secure Service (Encryption + OCR)
        result = process_document(file, property_id, doc_type.value)
        
        # Check Compliance (OCR Logic)
        status_doc = "verified" # Default for now
        metadata_str = ""
        
        if "metadata" in result and result["metadata"]:
            import json
            metadata_str = json.dumps(result["metadata"])
            
            # Auto-Verify if Catastral Ref matches?
            # For now just store metadata.
            
        new_doc = PropertyDocument(
            property_id=property.id,
            doc_type=doc_type,
            filename=file.filename,
            file_path=None,
            encrypted_content=result["encrypted_content"],
            is_encrypted=True,
            status=status_doc,
            extracted_metadata=metadata_str
        )
        db.add(new_doc)
        db.commit()
        db.refresh(new_doc)
        
        return {"id": new_doc.id, "status": status_doc, "metadata": result["metadata"]}
        
    except ComplianceError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload processing failed: {str(e)}")

@router.get("/{property_id}/documents")
async def list_documents(
    property_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    List compliance documents (Metadata Only).
    """
    property = verify_property_ownership(db, property_id, current_user.id)
    
    docs = db.query(PropertyDocument).filter(PropertyDocument.property_id == property_id).all()
    return docs

@router.get("/documents/{doc_id}/download")
async def download_document(
    doc_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Secure Download: Decrypts file on the fly and streams it.
    """
    doc = db.query(PropertyDocument).join(Property).filter(PropertyDocument.id == doc_id).first()
    
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
        
    # Access Control: Owner or Admin (Admin logic not here yet, assuming Owner)
    if doc.property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    try:
        # Decrypt from DB or legacy file_path
        if doc.encrypted_content:
            decrypted_bytes = get_decrypted_document(doc.encrypted_content)
        elif doc.file_path:
            decrypted_bytes = get_decrypted_document_from_path(doc.file_path)
        else:
            raise HTTPException(status_code=404, detail="Document content not found")

        from fastapi.responses import Response
        # Return as downloadable stream
        return Response(
            content=decrypted_bytes,
            media_type="application/octet-stream",
            headers={"Content-Disposition": f"attachment; filename={doc.filename}"}
        )
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Decryption failed")


@router.delete("/{property_id}/documents/{doc_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    property_id: int,
    doc_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Conditional Deletion of Compliance Documents.
    - PENDING/REJECTED: Allowed (Clean up file & DB).
    - VERIFIED: Forbidden (Immutable unless Admin overrides).
    """
    # 1. Verify Ownership & Existence
    doc = db.query(PropertyDocument).join(Property).filter(
        PropertyDocument.id == doc_id,
        PropertyDocument.property_id == property_id
    ).first()
    
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
        
    if doc.property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    # 2. Check Conditional Policy
    if doc.status == "verified":
        raise HTTPException(
            status_code=403, 
            detail="Cannot delete a VERIFIED document. Please request a change if necessary."
        )
        
    # 3. Execute Deletion
    try:
        # Delete File from Disk
        import os
        if os.path.exists(doc.file_path):
             os.remove(doc.file_path)
             
        # Delete from DB
        db.delete(doc)
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Deletion failed: {str(e)}")
    
    return None
