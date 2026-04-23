"""
Community Shield -- User Report Endpoints

Allows verified users to report suspected professional real estate
agents. Reports feed into the Active Intelligence Shield's risk
scoring system.
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.models.user_report import UserReport, ReportCategory
from backend.src.utils.security import get_current_active_user
from backend.src.utils.intelligence_shield import (
    should_trigger_reinvestigation,
    investigate_user_osint,
)

logger = logging.getLogger("inmufacil.community_shield")

router = APIRouter(prefix="/reports", tags=["Community Shield"])


# ============================================================================
# Schemas
# ============================================================================

class ReportCreate(BaseModel):
    """Schema for creating a user report."""
    reported_id: int = Field(..., gt=0, description="ID of the user being reported")
    reason_category: ReportCategory
    description: Optional[str] = Field(
        None, max_length=1000,
        description="Optional description of the suspicious behavior"
    )


class ReportResponse(BaseModel):
    """Schema for report creation response."""
    id: int
    reporter_id: int
    reported_id: int
    reason_category: str
    reinvestigation_triggered: bool

    class Config:
        from_attributes = True


# ============================================================================
# Validation Helpers
# ============================================================================

def validate_report_request(reporter_id: int, reported_id: int) -> Optional[str]:
    """
    Validate basic report constraints.

    Args:
        reporter_id: ID of the user filing the report.
        reported_id: ID of the user being reported.

    Returns:
        Error message string if invalid, None if valid.
    """
    if reporter_id == reported_id:
        return "You cannot report yourself."
    return None


def check_duplicate_report(
    db: Session,
    reporter_id: int,
    reported_id: int,
) -> bool:
    """
    Check if a report already exists for this reporter/reported pair.

    Args:
        db: Database session.
        reporter_id: ID of the reporting user.
        reported_id: ID of the reported user.

    Returns:
        True if a duplicate report exists.
    """
    existing = (
        db.query(UserReport)
        .filter(
            UserReport.reporter_id == reporter_id,
            UserReport.reported_id == reported_id,
        )
        .first()
    )
    return existing is not None


# ============================================================================
# Endpoints
# ============================================================================

@router.post(
    "/report-agent",
    response_model=ReportResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Report a suspected professional agent",
)
async def report_agent(
    report_data: ReportCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    File a report against a suspected professional real estate agent.

    Requirements:
    - Reporter must be a verified user (email_verified=True).
    - Reporter cannot report themselves.
    - Reporter cannot file duplicate reports against the same user.
    - If the reported user accumulates >= 3 reports, an automatic
      OSINT re-investigation is triggered.
    """
    # Validate reporter is email-verified
    if not current_user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only verified users can file reports.",
        )

    # Validate self-report
    error = validate_report_request(
        reporter_id=current_user.id,
        reported_id=report_data.reported_id,
    )
    if error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error,
        )

    # Check duplicate
    if check_duplicate_report(db, current_user.id, report_data.reported_id):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already reported this user.",
        )

    # Verify reported user exists
    reported_user = db.query(User).filter(User.id == report_data.reported_id).first()
    if not reported_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reported user not found.",
        )

    # Create report
    new_report = UserReport(
        reporter_id=current_user.id,
        reported_id=report_data.reported_id,
        reason_category=report_data.reason_category,
        description=report_data.description,
    )
    db.add(new_report)

    # Increment report_count on reported user
    reported_user.report_count = (reported_user.report_count or 0) + 1
    db.commit()
    db.refresh(new_report)
    db.refresh(reported_user)

    logger.info(
        "[COMMUNITY_SHIELD] Report filed: reporter=%d reported=%d "
        "category=%s new_count=%d",
        current_user.id,
        report_data.reported_id,
        report_data.reason_category.value,
        reported_user.report_count,
    )

    # Check if re-investigation should be triggered
    reinvestigation_triggered = False
    if should_trigger_reinvestigation(reported_user.report_count):
        reinvestigation_triggered = True
        logger.warning(
            "[COMMUNITY_SHIELD] Re-investigation triggered for user_id=%d "
            "(report_count=%d)",
            reported_user.id,
            reported_user.report_count,
        )
        # Trigger async OSINT re-investigation (best-effort, non-blocking)
        try:
            phone = ""
            if reported_user.encrypted_phone:
                # Phone is encrypted; in production, decrypt before investigating.
                # For now, use empty string (OSINT will rely on name search only).
                phone = ""
            await investigate_user_osint(
                email=reported_user.email,
                full_name=reported_user.full_name,
                phone=phone,
            )
        except Exception as exc:
            logger.error(
                "[COMMUNITY_SHIELD] Re-investigation failed for user_id=%d: %s",
                reported_user.id,
                exc,
            )

    return ReportResponse(
        id=new_report.id,
        reporter_id=new_report.reporter_id,
        reported_id=new_report.reported_id,
        reason_category=new_report.reason_category.value,
        reinvestigation_triggered=reinvestigation_triggered,
    )
