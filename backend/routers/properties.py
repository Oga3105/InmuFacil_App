"""
Properties Router
Handles CRUD operations for real estate listings with Advanced Data Intelligence.
@Jules: Implementation of Seller/Owner features.
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session, joinedload
from backend.database import get_db, Base, engine
from backend.models import (
    Property, User, PropertyFeatures, PropertyLegal, 
    PropertyFinancial, PropertyEnvironment, PropertyMedia, MediaType,
    Reservation, PropertyStatus, PropertyType, OperationType # Hito 8 + Search
)
from backend.schemas import PropertyCreate, PropertyResponse, PropertyMediaResponse, PropertyMediaCreate
from backend.security import get_current_active_user
from backend.services.image_service import validate_image, process_and_save_image
from backend.services.payment_service import MockPaymentProvider
from pydantic import BaseModel
from typing import Optional
from sqlalchemy import or_

# Ensure tables exist (fail-safe for new satellites)
Base.metadata.create_all(bind=engine)

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

@router.get("/", response_model=List[PropertyResponse])
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
        joinedload(Property.media)
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
        joinedload(Property.media)
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
    db.refresh(new_property)
    return new_property


@router.get("/me/all", response_model=List[PropertyResponse])
async def list_my_properties(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    List MY properties (Seller Panel).
    """
    return db.query(Property).options(
        joinedload(Property.features),
        joinedload(Property.legal),
        joinedload(Property.financial),
        joinedload(Property.media)
    ).filter(Property.owner_id == current_user.id).all()


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
    for key, value in core_data.items():
        setattr(property, key, value)
        
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
        file_path = process_and_save_image(file, property_id)
        
        # Determine is_main for this specific image in the batch
        # Only the first image of the batch gets is_main if user requested it, to avoid multiple mains
        current_is_main = is_main if i == 0 else False
        
        # Create DB Entry
        new_media = PropertyMedia(
            property_id=property.id,
            media_type=MediaType.IMAGE,
            file_path=file_path,
            is_main=current_is_main,
            order=0 # TODO: Logic to add at end
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
    db.refresh(new_media)
    return new_media

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
