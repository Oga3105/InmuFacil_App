from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.src.config.database import get_db
from backend.src.models import User, Property, PropertyFavorite
from backend.src.utils.security import get_current_active_user

router = APIRouter(tags=["Favorites"])

@router.post("/{property_id}", status_code=status.HTTP_200_OK)
async def toggle_favorite(
    property_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Toggle a property as favorite for the current user.
    If already favorite, remove it. If not, add it.
    """
    # Check if property exists
    prop = db.query(Property).filter(Property.id == property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")

    # Check if already favorite
    favorite = db.query(PropertyFavorite).filter(
        PropertyFavorite.user_id == current_user.id,
        PropertyFavorite.property_id == property_id
    ).first()

    if favorite:
        db.delete(favorite)
        db.commit()
        return {"status": "removed", "property_id": property_id}
    else:
        new_favorite = PropertyFavorite(
            user_id=current_user.id,
            property_id=property_id
        )
        db.add(new_favorite)
        db.commit()
        return {"status": "added", "property_id": property_id}

@router.get("/", response_model=List[int])
async def list_favorites(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    List all favorite property IDs for the current user.
    """
    favorites = db.query(PropertyFavorite.property_id).filter(
        PropertyFavorite.user_id == current_user.id
    ).all()
    
    # Extract IDs from list of tuples
    return [f[0] for f in favorites]
