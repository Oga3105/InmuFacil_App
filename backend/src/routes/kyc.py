import logging
import os
import shutil
from typing import List, Optional

from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from backend.src.config.database import SessionLocal, get_db
from backend.src.models import KYCVerification, User
from backend.src.models.enums import DNIStatus
from backend.src.utils.security import encrypt_data, get_current_active_user, get_current_admin_user
from backend.src.schemas.base import KYCStatusUpdate, KYCStatusResponse
from backend.src.services.gemini_kyc_service import verify_identity_with_gemini

logger = logging.getLogger(__name__)
router = APIRouter(tags=["KYC"])

UPLOAD_DIR = "uploads"


# ---------------------------------------------------------------------------
# Background task: AI verification
# ---------------------------------------------------------------------------

def _run_gemini_verification(
    user_id: int,
    front_path: Optional[str],
    back_path: Optional[str],
    selfie_path: Optional[str],
    document_type: str,
) -> None:
    """
    Runs in the background after the upload endpoint returns.
    Opens its own DB session (the request session is already closed).
    Calls Gemini, then updates KYCVerification records and User.dni_status.
    """
    db: Session = SessionLocal()
    try:
        result = verify_identity_with_gemini(
            front_path=front_path,
            back_path=back_path,
            selfie_path=selfie_path,
            document_type=document_type,
        )

        logger.info(
            "Gemini KYC result for user %s: approved=%s confidence=%.2f reason=%s",
            user_id, result.approved, result.confidence, result.reason,
        )

        # Quota exceeded → leave as pending, no rejection
        if result.reason == "__QUOTA_EXCEEDED__":
            logger.warning("Gemini quota exceeded for user %s; leaving status as pendiente", user_id)
            records = (
                db.query(KYCVerification)
                .filter(KYCVerification.user_id == user_id)
                .filter(KYCVerification.status == "pending")
                .all()
            )
            for rec in records:
                rec.status = "pendiente"
                rec.rejection_reason = None
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                user.dni_status = "SIN_VERIFICAR"
                user.rejection_reason = None
            db.commit()
            return

        new_status = "validado" if result.approved else "rechazado"
        new_dni_status = "VALIDADO" if result.approved else "RECHAZADO"

        # Update all KYCVerification records for this submission
        records = (
            db.query(KYCVerification)
            .filter(KYCVerification.user_id == user_id)
            .order_by(KYCVerification.id.desc())
            # Only update the latest batch (status is still 'pending')
            .filter(KYCVerification.status == "pending")
            .all()
        )
        for rec in records:
            rec.status = new_status
            if not result.approved:
                rec.rejection_reason = result.reason

        # Update the user
        user = db.query(User).filter(User.id == user_id).first()
        if user:
            user.dni_status = new_dni_status
            if not result.approved:
                user.rejection_reason = result.reason
            elif result.doc_number:
                from backend.src.utils.crypto import encrypt_data as _encrypt, compute_dni_hmac
                from sqlalchemy.exc import IntegrityError

                dni_hmac = compute_dni_hmac(result.doc_number)

                # Check for duplicate before committing to provide a clear error message
                existing = (
                    db.query(User)
                    .filter(User.dni_hmac == dni_hmac, User.id != user_id)
                    .first()
                )
                if existing:
                    # DNI already linked to another account — reject this verification
                    user.dni_status = "RECHAZADO"
                    user.rejection_reason = (
                        "Este documento de identidad ya esta vinculado a otra cuenta. "
                        "Si crees que es un error, contacta con soporte."
                    )
                    records_to_reject = (
                        db.query(KYCVerification)
                        .filter(KYCVerification.user_id == user_id, KYCVerification.status == "pending")
                        .all()
                    )
                    for rec in records_to_reject:
                        rec.status = "rechazado"
                        rec.rejection_reason = user.rejection_reason
                    logger.warning(
                        "[SHIELD] DNI duplicate detected: user_id=%s tried to register DNI already "
                        "linked to user_id=%s", user_id, existing.id
                    )
                    db.commit()
                    return

                user.encrypted_dni = _encrypt(result.doc_number)
                user.dni_hmac = dni_hmac

        try:
            db.commit()
        except Exception as integrity_exc:
            # Race condition: another request committed the same dni_hmac between
            # our SELECT and our INSERT. Treat as duplicate.
            db.rollback()
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                user.dni_status = "RECHAZADO"
                user.rejection_reason = (
                    "Este documento de identidad ya esta vinculado a otra cuenta. "
                    "Si crees que es un error, contacta con soporte."
                )
                user.encrypted_dni = None
                user.dni_hmac = None
                db.commit()
            logger.warning("[SHIELD] DNI uniqueness race condition for user_id=%s: %s", user_id, integrity_exc)
            return

    except Exception as e:
        logger.error("Gemini verification background task failed for user %s: %s", user_id, e)
        db.rollback()
    finally:
        db.close()


# ---------------------------------------------------------------------------
# User endpoints
# ---------------------------------------------------------------------------

@router.post("/upload")
async def upload_kyc_document(
    background_tasks: BackgroundTasks,
    front: UploadFile = File(None),
    back: UploadFile = File(None),
    selfie: UploadFile = File(None),
    document_type: str = Form("dni"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Subir documentos KYC (frente, reverso, selfie). La IA verifica automáticamente."""
    files = {"front": front, "back": back, "selfie": selfie}
    uploaded = {k: v for k, v in files.items() if v is not None}

    if not uploaded:
        raise HTTPException(status_code=400, detail="Debes subir al menos un archivo.")

    os.makedirs(UPLOAD_DIR, exist_ok=True)
    records_created = []
    saved_paths: dict[str, str] = {}

    for file_type_key, upload_file in uploaded.items():
        original_name = upload_file.filename or f"{file_type_key}.jpg"
        ext = os.path.splitext(original_name)[1].lower() or ".jpg"
        safe_filename = f"user_{current_user.id}_{file_type_key}{ext}"
        file_location = f"{UPLOAD_DIR}/{safe_filename}"

        try:
            with open(file_location, "wb") as buffer:
                shutil.copyfileobj(upload_file.file, buffer)
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Error guardando imagen ({file_type_key}): {str(e)}",
            )

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
        saved_paths[file_type_key] = file_location

    # Immediately mark as pending so the banner updates in the UI
    current_user.dni_status = DNIStatus.PENDIENTE
    db.commit()

    # Kick off AI verification asynchronously (non-blocking)
    background_tasks.add_task(
        _run_gemini_verification,
        user_id=current_user.id,
        front_path=saved_paths.get("front"),
        back_path=saved_paths.get("back"),
        selfie_path=saved_paths.get("selfie"),
        document_type=document_type,
    )

    return {
        "status": "pending",
        "files_uploaded": records_created,
        "msg": "Documentos subidos. Verificación automática en curso.",
    }


@router.get("/status", response_model=KYCStatusResponse)
async def get_my_kyc_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Ver el estado de mi última verificación KYC"""
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


# ---------------------------------------------------------------------------
# Admin endpoints
# ---------------------------------------------------------------------------

@router.get("/pending")
async def list_pending_kyc(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
):
    """(Admin) Listar verificaciones pendientes"""
    records = (
        db.query(KYCVerification)
        .filter(KYCVerification.status == "pending")
        .all()
    )
    return records


@router.put("/{verification_id}/review")
async def review_kyc(
    verification_id: int,
    status_update: KYCStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user),
):
    """(Admin) Aprobar o Rechazar manualmente un DNI (anula la decisión de IA)"""
    record = db.query(KYCVerification).filter(KYCVerification.id == verification_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    record.status = status_update.status
    record.rejection_reason = status_update.rejection_reason

    if record.user_id:
        user = db.query(User).filter(User.id == record.user_id).first()
        if user:
            if status_update.status == "validado":
                user.dni_status = "VALIDADO"
                user.rejection_reason = None
            elif status_update.status == "rechazado":
                user.dni_status = "RECHAZADO"
                user.rejection_reason = status_update.rejection_reason

    db.commit()
    return {"id": verification_id, "new_status": record.status}
