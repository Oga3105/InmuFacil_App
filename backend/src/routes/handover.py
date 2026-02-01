from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel

from backend.src.config.database import get_db
from backend.src.models.users import User
from backend.src.utils.security import get_current_active_user
from backend.src.services.handover_service import HandoverService

router = APIRouter(prefix="/handover", tags=["Post-Sales Handover"])

# Schemas
class HandoverUpdate(BaseModel):
    electricity_cups: Optional[str] = None
    gas_cups: Optional[str] = None
    water_reference: Optional[str] = None
    ibi_year_cost: Optional[float] = None
    community_fee_monthly: Optional[float] = None
    community_admin_contact: Optional[dict] = None

class HandoverResponse(BaseModel):
    id: int
    offer_id: int
    electricity_cups: Optional[str]
    bill_electricity_path: Optional[str] # Will be encrypted path, client shouldn't see path ideally, but API returns it relative? 
    # Actually, client needs to know IF it exists.
    has_electricity_bill: bool
    
    # We map fields manually in route to avoid exposing raw paths
    
    class Config:
        from_attributes = True

@router.get("/{offer_id}")
async def get_handover_dossier(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Get the Digital Handover Vault.
    Authorized: Seller, Buyer, Admin.
    """
    handover = HandoverService.get_handover(db, offer_id, current_user)
    
    return {
        "id": handover.id,
        "offer_id": handover.offer_id,
        "electricity_cups": handover.electricity_cups,
        "gas_cups": handover.gas_cups,
        "water_reference": handover.water_reference,
        "ibi_year_cost": handover.ibi_year_cost,
        "community_fee_monthly": handover.community_fee_monthly,
        "community_admin_contact": handover.community_admin_contact,
        "is_electricity_bill_uploaded": bool(handover.bill_electricity_path),
        "is_water_bill_uploaded": bool(handover.bill_water_path),
        "is_gas_bill_uploaded": bool(handover.bill_gas_path),
        "is_community_cert_uploaded": bool(handover.certificate_community_path),
        "is_ibi_receipt_uploaded": bool(handover.receipt_ibi_path),
    }

@router.post("/update/{offer_id}")
async def update_handover_data(
    offer_id: int,
    data: HandoverUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Update Utility Credentials & Contact Info.
    Authorized: Seller Only.
    """
    handover = HandoverService.upsert_handover_data(db, offer_id, current_user, data.dict(exclude_unset=True))
    return {"status": "updated", "id": handover.id}

@router.post("/upload/{offer_id}")
async def upload_handover_bill(
    offer_id: int,
    bill_type: str = Form(..., description="electricity, water, gas, community, ibi"),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Secure Upload for Bills.
    Authorized: Seller Only.
    """
    handover = await HandoverService.upload_bill(db, offer_id, current_user, bill_type, file)
    return {"status": "uploaded", "bill_type": bill_type}
