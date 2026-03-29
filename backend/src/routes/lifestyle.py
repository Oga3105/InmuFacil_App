from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models.lifestyle import UserLifestyleProfile
from backend.src.models.users import User
from backend.src.routes.auth import get_current_user

router = APIRouter(prefix="/lifestyle", tags=["Lifestyle"])


class LifestyleProfileRequest(BaseModel):
    lifestyle_pace: Optional[str] = None
    work_style: Optional[str] = None
    mobility_style: Optional[str] = None
    sleep_sensitivity: Optional[str] = None
    green_needs: Optional[str] = None
    profile_type: Optional[str] = None
    natural_light_weight: Optional[float] = Field(None, ge=0.0, le=1.0)
    social_weight: Optional[float] = Field(None, ge=0.0, le=1.0)
    ready_to_live_weight: Optional[float] = Field(None, ge=0.0, le=1.0)


class LifestyleProfileResponse(BaseModel):
    lifestyle_pace: Optional[str] = None
    work_style: Optional[str] = None
    mobility_style: Optional[str] = None
    sleep_sensitivity: Optional[str] = None
    green_needs: Optional[str] = None
    profile_type: Optional[str] = None
    natural_light_weight: Optional[float] = None
    social_weight: Optional[float] = None
    ready_to_live_weight: Optional[float] = None

    model_config = {"from_attributes": True}


@router.get("/profile", response_model=LifestyleProfileResponse)
def get_lifestyle_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = (
        db.query(UserLifestyleProfile)
        .filter(UserLifestyleProfile.user_id == current_user.id)
        .first()
    )
    if not profile:
        return LifestyleProfileResponse()
    return profile


@router.post("/profile", response_model=LifestyleProfileResponse)
def save_lifestyle_profile(
    body: LifestyleProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = (
        db.query(UserLifestyleProfile)
        .filter(UserLifestyleProfile.user_id == current_user.id)
        .first()
    )

    if profile:
        for field, value in body.model_dump(exclude_unset=True).items():
            setattr(profile, field, value)
    else:
        profile = UserLifestyleProfile(
            user_id=current_user.id, **body.model_dump(exclude_unset=True)
        )
        db.add(profile)

    db.commit()
    db.refresh(profile)
    return profile
