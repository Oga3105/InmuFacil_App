from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from backend.src.models.financing import EmploymentStatus

class MortgageProfileCreate(BaseModel):
    """
    Schema for creating/updating user financial profile.
    Sensitive Data.
    """
    monthly_net_income: float = Field(..., gt=0)
    monthly_debts: float = Field(0, ge=0)
    savings_available: float = Field(0, ge=0)
    
    employment_status: EmploymentStatus
    contract_years: int = Field(0, ge=0)
    age: int = Field(..., ge=18, le=100)

class MortgageProfileResponse(MortgageProfileCreate):
    id: int
    user_id: int
    updated_at: datetime
    
    class Config:
        from_attributes = True

class SimulationRequest(BaseModel):
    """
    Request to trigger a mortgage simulation.
    """
    amount: float = Field(..., gt=1000)
    years: int = Field(30, ge=5, le=40)

class SimulationResponse(BaseModel):
    id: int
    target_property_value: float
    asked_amount: float
    years: int
    solvency_score: int
    is_viable_internal: bool
    offers_snapshot: str # JSON String, frontend should parse
    created_at: datetime
    
    class Config:
        from_attributes = True

class AdvisorAssignmentRequest(BaseModel):
    advisor_email: str # User inputs the email of their advisor
