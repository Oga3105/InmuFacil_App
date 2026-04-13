from typing import List, Optional
import logging
import os
import shutil
from pathlib import Path

logger = logging.getLogger(__name__)
from fastapi import APIRouter, Depends, HTTPException, Response, status, UploadFile, File
from sqlalchemy.orm import Session
from backend.src.config.database import get_db
from backend.src.models import User, KYCVerification
from backend.src.models.enums import DNIStatus
from backend.src.schemas.base import UserCreate, UserResponse, UserUpdate
from backend.src.utils.security import get_current_active_user, get_password_hash, encrypt_data, decrypt_data, get_current_admin_user

router = APIRouter(tags=["Users"])

# Usar CWD garantiza el path correcto independientemente de cómo se invoca uvicorn
UPLOADS_DIR = Path(os.getcwd()) / "uploads" / "avatars"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_FILE_SIZE_MB = 5



def _build_user_response(user: User, decrypted_phone: Optional[str] = None) -> UserResponse:
    """Helper to build a UserResponse from a User model, avoiding repetition."""
    return UserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        user_type=user.user_type,
        dni_status=user.dni_status.value if user.dni_status else "sin_verificar",
        is_active=user.is_active,
        created_at=user.created_at,
        updated_at=user.updated_at,
        rejection_reason=user.rejection_reason,
        phone=decrypted_phone,
        profile_photo_url=user.profile_photo_url,
        email_notifications_enabled=user.email_notifications_enabled
            if user.email_notifications_enabled is not None else True,
    )


# --- ENDPOINTS DE PERFIL (Usuario Logueado) ---

@router.get("/me", response_model=UserResponse)
async def read_users_me(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Ver mi propio perfil.
    Decrypts phone number for the owner.
    Auto-heals stale 'pendiente' status for users who never submitted KYC documents.
    """
    decrypted_phone = None
    if current_user.encrypted_phone:
        try:
            decrypted_phone = decrypt_data(current_user.encrypted_phone)
        except Exception:
            decrypted_phone = None

    # Auto-heal: if dni_status is 'pendiente' but no KYC record exists, reset to 'sin_verificar'
    if current_user.dni_status == DNIStatus.PENDIENTE:
        has_kyc = db.query(KYCVerification).filter(
            KYCVerification.user_id == current_user.id
        ).first() is not None
        if not has_kyc:
            current_user.dni_status = DNIStatus.SIN_VERIFICAR
            db.commit()
            db.refresh(current_user)

    return _build_user_response(current_user, decrypted_phone)


@router.put("/me", response_model=UserResponse)
async def update_user_me(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Actualizar mis datos (Nombre, Teléfono). Email prohibido."""
    if user_update.full_name:
        current_user.full_name = user_update.full_name

    if user_update.phone:
        current_user.encrypted_phone = encrypt_data(user_update.phone)

    if user_update.email_notifications_enabled is not None:
        current_user.email_notifications_enabled = user_update.email_notifications_enabled

    db.commit()
    db.refresh(current_user)

    decrypted_phone = user_update.phone if user_update.phone else None
    if not decrypted_phone and current_user.encrypted_phone:
        try:
            decrypted_phone = decrypt_data(current_user.encrypted_phone)
        except Exception as e:
            logger.error(f"Error decrypting phone: {e}")

    return _build_user_response(current_user, decrypted_phone)


@router.post("/me/photo", response_model=UserResponse)
async def upload_profile_photo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Subir o reemplazar la foto de perfil del usuario autenticado.
    Acepta: JPEG, PNG, WebP. Tamaño máximo: 5 MB.
    """
    # Validar tipo MIME
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Tipo de archivo no permitido. Solo se aceptan: {', '.join(ALLOWED_CONTENT_TYPES)}",
        )

    # Leer contenido y validar tamaño
    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE_MB * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"La imagen supera el tamaño máximo de {MAX_FILE_SIZE_MB} MB.",
        )

    # Store in PostgreSQL as BYTEA — no filesystem writes
    current_user.profile_photo_data = contents
    current_user.profile_photo_content_type = file.content_type
    current_user.profile_photo_url = f"/api/v1/users/{current_user.id}/photo"
    db.commit()
    db.refresh(current_user)

    logger.info(f"[PHOTO] User {current_user.id} uploaded profile photo: {current_user.profile_photo_url}")

    # Decryptar teléfono si existe
    decrypted_phone = None
    if current_user.encrypted_phone:
        try:
            decrypted_phone = decrypt_data(current_user.encrypted_phone)
        except Exception:
            pass

    return _build_user_response(current_user, decrypted_phone)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_own_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Borrado permanente de la propia cuenta (GDPR — derecho al olvido).
    Elimina el registro completo del usuario de la base de datos.
    Usado cuando el usuario rechaza el consentimiento GDPR en el onboarding.
    """
    user_id = current_user.id
    db.delete(current_user)
    db.commit()
    logger.info(f"[GDPR] User {user_id} deleted their own account (consent declined).")
    return None


@router.delete("/me/photo", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile_photo(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Eliminar la foto de perfil del usuario autenticado.
    Borra el archivo del disco y limpia la URL en base de datos.
    """
    if current_user.profile_photo_url is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El usuario no tiene foto de perfil.",
        )

    current_user.profile_photo_data = None
    current_user.profile_photo_content_type = None
    current_user.profile_photo_url = None
    db.commit()

    logger.info(f"[PHOTO] User {current_user.id} deleted profile photo")
    return None


@router.get("/{user_id}/photo")
async def get_user_photo(user_id: int, db: Session = Depends(get_db)):
    """Serve a user's profile photo stored as BYTEA. Public endpoint."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.profile_photo_data:
        raise HTTPException(status_code=404, detail="Photo not found")
    return Response(
        content=user.profile_photo_data,
        media_type=user.profile_photo_content_type or "image/jpeg",
        headers={"Cache-Control": "public, max-age=86400"},
    )


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
            phone=None,
            profile_photo_url=u.profile_photo_url,
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
