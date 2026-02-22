from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.src.config.database import get_db
from backend.src.models import User, UserType
from backend.src.models.financing import MortgageProfile, MortgageSimulation
from backend.src.schemas.financing import (
    MortgageProfileCreate, MortgageProfileResponse, 
    SimulationRequest, SimulationResponse, AdvisorAssignmentRequest
)
from backend.src.services.financing_service import FinancingService
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/financing", tags=["Financing"])

@router.post("/profile", response_model=MortgageProfileResponse)
async def upsert_financial_profile(
    profile_data: MortgageProfileCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Create or Update the Financial Profile of the current user.
    """
    # Check if exists
    profile = db.query(MortgageProfile).filter(MortgageProfile.user_id == current_user.id).first()
    
    if not profile:
        profile = MortgageProfile(user_id=current_user.id, **profile_data.dict())
        db.add(profile)
    else:
        # Update
        for key, value in profile_data.dict().items():
            setattr(profile, key, value)
            
    db.commit()
    db.refresh(profile)
    return profile

@router.get("/profile", response_model=MortgageProfileResponse)
async def get_my_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Retrieve own financial profile.
    """
    profile = db.query(MortgageProfile).filter(MortgageProfile.user_id == current_user.id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not set")
    return profile

@router.post("/simulate", response_model=SimulationResponse)
async def run_simulation(
    request: SimulationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Run a mortgage simulation based on valid profile.
    """
    try:
        simulation = FinancingService.simulate_mortgage(
            db, current_user.id, request.amount, request.years
        )
        return simulation
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/history", response_model=List[SimulationResponse])
async def get_simulation_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    return db.query(MortgageSimulation).filter(
        MortgageSimulation.user_id == current_user.id
    ).order_by(MortgageSimulation.created_at.desc()).all()

@router.post("/assign", status_code=status.HTTP_200_OK)
async def assign_advisor(
    request: AdvisorAssignmentRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Assign a 'Financiero' to the current user.
    """
    advisor = db.query(User).filter(
        User.email == request.advisor_email,
        User.user_type == UserType.FINANCIERO
    ).first()
    
    if not advisor:
         raise HTTPException(status_code=404, detail="Advisor not found or invalid type")
         
    current_user.financial_advisor_id = advisor.id
    db.commit()
    return {"message": f"assigned to {advisor.full_name}"}
