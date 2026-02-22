from typing import List, Optional
import logging

logger = logging.getLogger(__name__)
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.schemas.base import UserCreate, UserResponse, UserUpdate
from backend.src.utils.security import get_current_active_user, get_password_hash, encrypt_data, decrypt_data, get_current_admin_user
# Usamos encrypt_data de security.py, no filters.py

router = APIRouter(tags=["Users"])

# --- ENDPOINTS DE PERFIL (Usuario Logueado) ---

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    """
    Ver mi propio perfil.
    Decrypts phone number for the owner.
    """
    # Decrypt phone if exists
    decrypted_phone = None
    if current_user.encrypted_phone:
        try:
            decrypted_phone = decrypt_data(current_user.encrypted_phone)
        except Exception:
            decrypted_phone = None

    # Construct response manually to include decrypted phone
    response_data = UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        user_type=current_user.user_type,
        dni_status=current_user.dni_status.value if current_user.dni_status else "pendiente",
        is_active=current_user.is_active,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
        rejection_reason=current_user.rejection_reason,
        phone=decrypted_phone
    )
    return response_data

@router.put("/me", response_model=UserResponse)
async def update_user_me(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Actualizar mis datos (Nombre, Teléfono). Email prohibido."""
    
    # Actualizar campos permitidos
    if user_update.full_name:
        current_user.full_name = user_update.full_name
    
    # Campo 'phone' en schema -> 'encrypted_phone' en modelo
    if user_update.phone:
        current_user.encrypted_phone = encrypt_data(user_update.phone)

    db.commit()
    db.refresh(current_user)
    
    # Return updated data with decrypted phone
    decrypted_phone = user_update.phone if user_update.phone else None
    if not decrypted_phone and current_user.encrypted_phone:
         try:
            decrypted_phone = decrypt_data(current_user.encrypted_phone)
         except Exception as e:
            logger.error(f"Error decrypting phone: {e}")

    response_data = UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        user_type=current_user.user_type,
        dni_status=current_user.dni_status.value if current_user.dni_status else "pendiente",
        is_active=current_user.is_active,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
        rejection_reason=current_user.rejection_reason,
        phone=decrypted_phone
    )
    return response_data

# --- ENDPOINTS DE ADMINISTRACIÓN (Solo Admins) ---

@router.get("/", response_model=List[UserResponse])
async def read_users(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Listar todos los usuarios (Solo Admin)"""
    users = db.query(User).offset(skip).limit(limit).all()
    # Map to schema, phone is hidden/None for admin list
    return [
        UserResponse(
            id=u.id,
            email=u.email,
            full_name=u.full_name,
            user_type=u.user_type,
            dni_status=u.dni_status.value if u.dni_status else "pendiente",
            is_active=u.is_active,
            created_at=u.created_at,
            updated_at=u.updated_at,
            rejection_reason=u.rejection_reason,
            phone=None 
        ) for u in users
    ]

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Soft Delete de usuario (Solo Admin)"""
    user_to_delete = db.query(User).filter(User.id == user_id).first()
    if not user_to_delete:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    if user_to_delete.email == "admin@inmufacil.com":
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete the super admin"
        )
        
    # Soft Delete
    user_to_delete.is_active = False
    db.commit()
    return None
