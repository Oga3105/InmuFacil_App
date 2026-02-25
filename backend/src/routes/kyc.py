import os
import shutil
from typing import List, Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends, status
from sqlalchemy.orm import Session
from backend.src.config.database import get_db
from backend.src.models import KYCVerification, User
from backend.src.models.enums import DNIStatus
from backend.src.utils.security import encrypt_data, get_current_active_user, get_current_admin_user
from backend.src.schemas.base import KYCStatusUpdate, KYCStatusResponse

router = APIRouter(tags=["KYC"])

UPLOAD_DIR = "uploads"

# --- ENDPOINTS DE USUARIO (Subida y Estado) ---

@router.post("/upload")
async def upload_kyc_document(
    front: UploadFile = File(None),
    back: UploadFile = File(None),
    selfie: UploadFile = File(None),
    document_type: str = Form("dni"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Subir documentos KYC (frente, reverso, selfie) para verificación"""
    files = {"front": front, "back": back, "selfie": selfie}
    uploaded = {k: v for k, v in files.items() if v is not None}

    if not uploaded:
        raise HTTPException(status_code=400, detail="Debes subir al menos un archivo.")

    os.makedirs(UPLOAD_DIR, exist_ok=True)
    records_created = []

    for file_type_key, upload_file in uploaded.items():
        safe_filename = f"user_{current_user.id}_{file_type_key}_{upload_file.filename}"
        file_location = f"{UPLOAD_DIR}/{safe_filename}"

        try:
            with open(file_location, "wb") as buffer:
                shutil.copyfileobj(upload_file.file, buffer)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error guardando imagen ({file_type_key}): {str(e)}")

        encrypted_blob = encrypt_data(f"FILE:{safe_filename}")

        db_record = KYCVerification(
            user_id=current_user.id,
            filename=safe_filename,
            dni_encrypted=encrypted_blob,
            status="pending",
            file_type=file_type_key,
            document_type=document_type,
        )
        db.add(db_record)
        records_created.append(file_type_key)

    # Update user status to pending
    current_user.dni_status = DNIStatus.PENDIENTE
    db.commit()

    return {
        "status": "pending",
        "files_uploaded": records_created,
        "msg": "Documentos subidos. Esperando revisión.",
    }


@router.get("/status", response_model=KYCStatusResponse)
async def get_my_kyc_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Ver el estado de mi última verificación"""
    record = (
        db.query(KYCVerification)
        .filter(KYCVerification.user_id == current_user.id)
        .order_by(KYCVerification.id.desc())
        .first()
    )

    if not record:
        return KYCStatusResponse(status="unverified")

    return KYCStatusResponse(
        status=record.status,
        rejection_reason=record.rejection_reason,
        upload_date=record.upload_date,
        document_type=record.document_type,
    )


# --- ENDPOINTS DE ADMIN (Revisión) ---

@router.get("/pending")
async def list_pending_kyc(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
):
    """(Admin) Listar verificaciones pendientes"""
    records = db.query(KYCVerification).filter(KYCVerification.status == "pending").all()
    return records


@router.put("/{verification_id}/review")
async def review_kyc(
    verification_id: int,
    status_update: KYCStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
):
    """(Admin) Aprobar o Rechazar un DNI"""
    record = db.query(KYCVerification).filter(KYCVerification.id == verification_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    record.status = status_update.status
    record.rejection_reason = status_update.rejection_reason

    # Sync user status
    if record.user_id:
        user = db.query(User).filter(User.id == record.user_id).first()
        if user:
            if status_update.status == "validado":
                user.dni_status = DNIStatus.VALIDADO
                user.rejection_reason = None
            elif status_update.status == "rechazado":
                user.dni_status = DNIStatus.RECHAZADO
                user.rejection_reason = status_update.rejection_reason

    db.commit()

    return {"id": verification_id, "new_status": record.status}
