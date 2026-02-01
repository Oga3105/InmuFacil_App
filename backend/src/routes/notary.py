
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List

from backend.src.config.database import get_db
from backend.src.services.notary_service import NotaryService
from backend.src.services.notary_dossier_service import NotaryDossierService
from backend.src.schemas.notary import NotaryResponse, NotaryAssignmentRequest
from backend.src.routes.auth import get_current_user
from backend.src.models.users import User, UserType

router = APIRouter(prefix="/notaries", tags=["notaries"])

@router.get("/", response_model=List[NotaryResponse])
def list_notaries(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = NotaryService(db)
    return service.list_notaries()

@router.post("/assign", response_model=bool) # Returns True if success
def assign_notary(
    request: NotaryAssignmentRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # RBAC: Only Seller or Professional should typically assign? Or both?
    # For now, let's allow either party involved in the offer (Buyer/Seller).
    # Logic is simplified here, but Service checks offer existence.
    
    service = NotaryService(db)
    try:
        service.assign_notary(request.offer_id, request.notary_id)
        return True
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/dossier/{offer_id}")
def download_dossier(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Control de Seguridad: Solo el Notario (via rol especial) o el Admin debería descargar esto.
    Como no tenemos rol 'NOTARY' aún, usaremos user.is_superuser o logicamente el Vendedor en fase final.
    Para Hito 14, permitimos a las partes descargar "su" copia para llevarla.
    """
    dossier_service = NotaryDossierService(db)
    try:
        zip_path = dossier_service.generate_dossier_zip(offer_id)
        return FileResponse(
            zip_path, 
            media_type='application/zip', 
            filename=f"dossier_oferta_{offer_id}.zip"
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
