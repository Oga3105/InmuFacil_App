from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from enum import Enum
from pydantic import BaseModel

from backend.src.services.cost_estimator_service import CostEstimatorService

router = APIRouter(prefix="/financial", tags=["Financial Intelligence"])

class RegionEnum(str, Enum):
    MADRID = "MADRID"
    CATALONIA = "CATALONIA"
    ANDALUSIA = "ANDALUSIA"
    VALENCIA = "VALENCIA"
    GALICIA = "GALICIA"
    OTHER = "OTHER"

class CostEstimateResponse(BaseModel):
    input_price: float
    region: str
    tax_name: str
    tax_amount: float
    notary_estimated: float
    registry_estimated: float
    total_estimated_costs: float
    grand_total: float
    legal_disclaimer: str

@router.get("/purchase-estimate", response_model=CostEstimateResponse)
async def get_purchase_estimate(
    price: float = Query(..., gt=0, description="Property Price in EUR"),
    region: RegionEnum = Query(..., description="Autonomous Community"),
    is_new_construction: bool = Query(False, description="Is it a new build (New vs Resale)?")
):
    """
    Hito 16: Early Cost Intelligence.
    Returns an ESTIMATE of the transaction costs (Taxes, Notary, Registry).
    """
    try:
        result = CostEstimatorService.calculate_purchase_costs(
            price=price,
            region=region.value,
            is_new_construction=is_new_construction
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
