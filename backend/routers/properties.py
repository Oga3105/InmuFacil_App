"""
Properties Router
Handles CRUD operations for real estate listings.
@Jules: Implementation of Seller/Owner features.
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.database import get_db, Base, engine
from backend.models import Property, User
from backend.schemas import PropertyCreate, PropertyResponse
from backend.security import get_current_active_user

# Ensure table exists (fail-safe)
Base.metadata.create_all(bind=engine)

router = APIRouter(prefix="/properties", tags=["Properties"])


# ============================================================================
# Public Endpoints
# ============================================================================

@router.get("/", response_model=List[PropertyResponse])
async def list_properties(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    """
    List all properties (Public Catalog).
    """
    properties = db.query(Property).offset(skip).limit(limit).all()
    return properties


@router.get("/{property_id}", response_model=PropertyResponse)
async def get_property(
    property_id: int, 
    db: Session = Depends(get_db)
):
    """
    Get specific property details.
    """
    property = db.query(Property).filter(Property.id == property_id).first()
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
    Create a new property listing.
    """
    new_property = Property(
        **property_data.model_dump(),
        owner_id=current_user.id
    )
    db.add(new_property)
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
    return db.query(Property).filter(Property.owner_id == current_user.id).all()


@router.put("/{property_id}", response_model=PropertyResponse)
async def update_property(
    property_id: int,
    property_update: PropertyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Update a property listing.
    SECURITY: Only the owner can update their property.
    """
    property = db.query(Property).filter(Property.id == property_id).first()
    if not property:
        raise HTTPException(status_code=404, detail="Property not found")
        
    if property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this property")
        
    # Update fields
    for key, value in property_update.model_dump().items():
        setattr(property, key, value)
        
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
    SECURITY: Only the owner can delete their property.
    """
    property = db.query(Property).filter(Property.id == property_id).first()
    if not property:
        raise HTTPException(status_code=404, detail="Property not found")
        
    if property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this property")
        
    db.delete(property)
    db.commit()
    return None
