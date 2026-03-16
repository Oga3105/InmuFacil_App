"""
Post-Sale document management endpoints.
@Shield: RBAC — only seller uploads, only buyer+seller of the same offer can access.
@Jules: Gate — documents only accessible when DEED_SIGNATURE step is COMPLETED.
"""
import os
from pathlib import Path
from typing import List

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from fastapi.responses import FileResponse
from pydantic import BaseModel
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.utils.security import get_current_active_user
from backend.src.models.users import User
from backend.src.models.offers import PropertyOffer
from backend.src.models.post_sale import PostSaleDocument, PostSaleDocType, PostSaleDocFlag
from backend.src.models.timeline import TransactionStep, StepStatus

router = APIRouter(prefix="/post-sale", tags=["Post-Sale"])

UPLOAD_DIR = Path("uploads/post_sale")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_TYPES = {"application/pdf", "image/jpeg", "image/png"}
MAX_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB


# ─── Internal helpers ────────────────────────────────────────────────────────

def _require_deed_completed(offer_id: int, db: Session) -> None:
    """
    Raises 403 unless both parties have confirmed the notaría signing.

    Accepts either:
      (a) step.status == COMPLETED  (normal path), OR
      (b) both buyer_confirmed_at and seller_confirmed_at are set
          (belt-and-suspenders: covers state inconsistency between enum and metadata).
    """
    step = (
        db.query(TransactionStep)
        .filter(
            TransactionStep.offer_id == offer_id,
            TransactionStep.step_key == "NOTARIA_APPOINTMENT",
        )
        .first()
    )

    if step is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Documentos de post-venta accesibles solo tras la firma en notaria.",
        )

    enum_completed = step.status == StepStatus.COMPLETED
    both_confirmed = (
        step.buyer_confirmed_at is not None
        and step.seller_confirmed_at is not None
    )

    if not (enum_completed or both_confirmed):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Documentos de post-venta accesibles solo tras la firma en notaria.",
        )

    # Auto-repair: if both confirmed but enum is stale, fix it now.
    if both_confirmed and not enum_completed:
        step.status = StepStatus.COMPLETED
        db.commit()


def _get_offer_or_404(offer_id: int, db: Session) -> PropertyOffer:
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta no encontrada.")
    return offer


def _require_participant(offer: PropertyOffer, user: User) -> None:
    """Ensures the requesting user is buyer or seller of the offer."""
    is_buyer  = offer.buyer_id == user.id
    is_seller = offer.property.owner_id == user.id
    if not (is_buyer or is_seller):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo las partes de la oferta pueden acceder.",
        )


def _save_post_sale_document(
    offer_id: int,
    user_id: int,
    doc_type: str,
    file: UploadFile,
    db: Session,
) -> dict:
    """Persists the uploaded file and creates a DB record."""
    content = file.file.read()
    if len(content) > MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Archivo demasiado grande. Maximo 10 MB.",
        )

    dest_dir = UPLOAD_DIR / str(offer_id)
    dest_dir.mkdir(parents=True, exist_ok=True)
    safe_name = f"{doc_type}_{file.filename}"
    dest_path = dest_dir / safe_name

    with open(dest_path, "wb") as f:
        f.write(content)

    doc = PostSaleDocument(
        offer_id=offer_id,
        uploaded_by=user_id,
        doc_type=PostSaleDocType(doc_type),
        filename=file.filename,
        file_path=str(dest_path),
        file_size=len(content),
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)
    return {"id": doc.id, "doc_type": doc.doc_type, "filename": doc.filename}


def _list_post_sale_documents(offer_id: int, db: Session) -> List[dict]:
    """Returns all post-sale documents for the offer."""
    docs = (
        db.query(PostSaleDocument)
        .filter(PostSaleDocument.offer_id == offer_id)
        .order_by(PostSaleDocument.created_at.asc())
        .all()
    )
    return [
        {
            "id": d.id,
            "doc_type": d.doc_type,
            "filename": d.filename,
            "file_size": d.file_size,
            "created_at": d.created_at.isoformat() if d.created_at else None,
        }
        for d in docs
    ]


# ─── Response schemas ─────────────────────────────────────────────────────────

class DocumentOut(BaseModel):
    id: int
    doc_type: str
    filename: str
    file_size: int | None = None
    created_at: str | None = None

    class Config:
        from_attributes = True


# ─── Endpoints ───────────────────────────────────────────────────────────────

_VALID_FLAGS = {"in_person", "not_applicable"}


class DocFlagRequest(BaseModel):
    doc_type: str
    flag: str  # "in_person" | "not_applicable"


class DocStatusItem(BaseModel):
    status: str | None = None   # "uploaded" | "in_person" | "not_applicable" | None
    doc_id: int | None = None
    filename: str | None = None


@router.get("/{offer_id}/status")
async def get_doc_status(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> dict:
    """
    Returns the combined delivery status for every doc type.
    Priority: uploaded file > flag (in_person/not_applicable) > None.
    """
    _require_deed_completed(offer_id, db)
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)

    uploaded = (
        db.query(PostSaleDocument)
        .filter(PostSaleDocument.offer_id == offer_id)
        .all()
    )
    flags = (
        db.query(PostSaleDocFlag)
        .filter(PostSaleDocFlag.offer_id == offer_id)
        .all()
    )

    uploaded_map = {d.doc_type.value: {"doc_id": d.id, "filename": d.filename} for d in uploaded}
    flag_map = {f.doc_type.value: f.flag for f in flags}

    result = {}
    for doc_type in PostSaleDocType:
        key = doc_type.value
        if key in uploaded_map:
            result[key] = {
                "status": "uploaded",
                "doc_id": uploaded_map[key]["doc_id"],
                "filename": uploaded_map[key]["filename"],
            }
        elif key in flag_map:
            result[key] = {"status": flag_map[key], "doc_id": None, "filename": None}
        else:
            result[key] = {"status": None, "doc_id": None, "filename": None}

    return result


@router.post("/{offer_id}/flag")
async def set_doc_flag(
    offer_id: int,
    body: DocFlagRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Buyer or Seller mark a doc type as delivered in person or not applicable.
    Either party can set the flag — last writer wins.
    Upserts the flag (one per offer+doc_type).
    """
    _require_deed_completed(offer_id, db)
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)
    if body.doc_type not in [t.value for t in PostSaleDocType]:
        raise HTTPException(status_code=422, detail="Tipo de documento invalido.")
    if body.flag not in _VALID_FLAGS:
        raise HTTPException(
            status_code=422,
            detail=f"Flag invalido. Valores: {list(_VALID_FLAGS)}",
        )

    existing = (
        db.query(PostSaleDocFlag)
        .filter(
            PostSaleDocFlag.offer_id == offer_id,
            PostSaleDocFlag.doc_type == body.doc_type,
        )
        .first()
    )
    if existing:
        existing.flag = body.flag
        existing.set_by = current_user.id
    else:
        db.add(PostSaleDocFlag(
            offer_id=offer_id,
            doc_type=body.doc_type,
            flag=body.flag,
            set_by=current_user.id,
        ))
    db.commit()
    return {"doc_type": body.doc_type, "flag": body.flag}


@router.get("/{offer_id}/documents", response_model=List[DocumentOut])
async def list_documents(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    List all post-sale documents for an offer.
    Gate: DEED_SIGNATURE must be COMPLETED.
    RBAC: Only buyer or seller of the offer.
    """
    _require_deed_completed(offer_id, db)
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)
    return _list_post_sale_documents(offer_id, db)


@router.post("/{offer_id}/documents", response_model=DocumentOut)
async def upload_document(
    offer_id: int,
    doc_type: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Upload a post-sale document (Seller only).
    Gate: DEED_SIGNATURE must be COMPLETED.
    Allowed types: electricity, water, gas, ibi, community.
    Max size: 10 MB. Allowed formats: PDF, JPG, PNG.
    """
    _require_deed_completed(offer_id, db)
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)

    # @Shield: seller-only upload
    if offer.buyer_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el vendedor puede subir documentos de post-venta.",
        )

    if doc_type not in [t.value for t in PostSaleDocType]:
        raise HTTPException(
            status_code=422,
            detail=f"Tipo de documento invalido. Valores permitidos: {[t.value for t in PostSaleDocType]}",
        )

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=422,
            detail="Formato de archivo no permitido. Use PDF, JPG o PNG.",
        )

    return _save_post_sale_document(offer_id, current_user.id, doc_type, file, db)


@router.get("/{offer_id}/documents/{doc_id}/download")
async def download_document(
    offer_id: int,
    doc_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Download a specific post-sale document.
    Gate: DEED_SIGNATURE must be COMPLETED.
    RBAC: Only buyer or seller.
    """
    _require_deed_completed(offer_id, db)
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)

    doc = (
        db.query(PostSaleDocument)
        .filter(
            PostSaleDocument.id == doc_id,
            PostSaleDocument.offer_id == offer_id,
        )
        .first()
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Documento no encontrado.")

    if not os.path.exists(doc.file_path):
        raise HTTPException(
            status_code=404, detail="Archivo no disponible en el servidor."
        )

    return FileResponse(
        path=doc.file_path,
        filename=doc.filename,
        media_type="application/octet-stream",
    )
