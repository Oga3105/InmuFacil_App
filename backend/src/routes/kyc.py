import os
import shutil
from typing import List
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, status
from sqlalchemy.orm import Session
from backend.src.config.database import get_db, engine
from backend.src.models import KYCVerification, User
from backend.src.utils.security import encrypt_data, get_current_active_user, get_current_admin_user
from backend.src.schemas.base import KYCStatusUpdate

# Aseguramos que la tabla exista (aunque ya la creamos via docker exec, esto es fail-safe)
# Base.metadata.create_all(bind=engine)

router = APIRouter(tags=["KYC"])

# --- ENDPOINTS DE USUARIO (Subida y Estado) ---

@router.post("/upload")
async def upload_kyc_document(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Subir DNI para verificación"""
    # 1. Preparar carpeta
    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)
    
    # 2. Guardar archivo físico (Renombramos con ID de usuario para evitar colisiones)
    safe_filename = f"user_{current_user.id}_{file.filename}"
    file_location = f"{upload_dir}/{safe_filename}"
    
    try:
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error guardando imagen: {str(e)}")

    # 3. Guardar registro en BD (Cifrado)
    # Usamos encrypt_data de security.py
    encrypted_blob = encrypt_data(f"FILE:{safe_filename}")
    
    db_record = KYCVerification(
        filename=safe_filename,
        dni_encrypted=encrypted_blob,
        status="pending" # Por defecto entra en pendiente
    )
    
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    
    return {"status": "pending", "msg": "Documento subido. Esperando revisión."}

@router.get("/status")
async def get_my_kyc_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Ver el estado de mi última verificación"""
    # Buscamos por nombre de archivo que contenga el ID del usuario
    record = db.query(KYCVerification).filter(KYCVerification.filename.contains(f"user_{current_user.id}_")).order_by(KYCVerification.id.desc()).first()
    
    if not record:
        return {"status": "unverified"}
    return {"status": record.status, "date": record.upload_date}

# --- ENDPOINTS DE ADMIN (Revisión) ---

@router.get("/pending")
async def list_pending_kyc(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """(Admin) Listar verificaciones pendientes"""
    # El dependency get_current_admin_user ya valida el permiso
    records = db.query(KYCVerification).filter(KYCVerification.status == "pending").all()
    return records

@router.put("/{verification_id}/review")
async def review_kyc(
    verification_id: int,
    status_update: KYCStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """(Admin) Aprobar o Rechazar un DNI"""
    # El dependency get_current_admin_user ya valida el permiso
    
    record = db.query(KYCVerification).filter(KYCVerification.id == verification_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
        
    record.status = status_update.status
    db.commit()
    
    return {"id": verification_id, "new_status": record.status}
