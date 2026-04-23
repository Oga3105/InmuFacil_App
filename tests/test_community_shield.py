"""
Community Shield -- Test Suite

Validates the P2P user reporting system that feeds into the
Active Intelligence Shield's risk scoring.

Tests cover:
- Report creation and persistence
- Duplicate report prevention (same reporter/reported pair)
- Risk score increment per report (+25 per distinct reporter)
- Automatic OSINT re-investigation at report threshold (3)
- Self-report prevention
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime

from backend.src.models.user_report import UserReport, ReportCategory
from backend.src.utils.intelligence_shield import (
    calculate_risk_score,
    WEIGHT_PHONE_PORTAL,
    WEIGHT_NAME_PROFESSIONAL,
    WEIGHT_DISPOSABLE_EMAIL,
)


# ============================================================================
# Model Tests
# ============================================================================

def test_user_report_model_fields():
    """UserReport model should have all required fields."""
    report = UserReport(
        reporter_id=1,
        reported_id=2,
        reason_category=ReportCategory.PROFESIONAL_CAMUFLADO,
        description="This user asks for commission on visits.",
    )
    assert report.reporter_id == 1
    assert report.reported_id == 2
    assert report.reason_category == ReportCategory.PROFESIONAL_CAMUFLADO
    assert report.description == "This user asks for commission on visits."


def test_report_category_enum_values():
    """ReportCategory should have the three required categories."""
    assert ReportCategory.PROFESIONAL_CAMUFLADO.value == "profesional_camuflado"
    assert ReportCategory.PIDE_COMISION.value == "pide_comision"
    assert ReportCategory.DATOS_INEXACTOS.value == "datos_inexactos"


# ============================================================================
# Risk Scoring with Reports
# ============================================================================

def test_reporting_increases_risk_score():
    """
    Each verified report from a distinct user should add +25 to the
    risk score. After 3 reports (75 points) combined with any other
    factor, the user should exceed the blocking threshold.
    """
    from backend.src.utils.intelligence_shield import calculate_risk_score_with_reports

    # 3 distinct reports = 75 points
    score = calculate_risk_score_with_reports(
        phone_match=False,
        name_match=False,
        disposable_email=False,
        report_count=3,
    )
    assert score == 75, f"3 reports should give 75 points, got {score}"

    # 3 reports + disposable email = 95 (blocked)
    score = calculate_risk_score_with_reports(
        phone_match=False,
        name_match=False,
        disposable_email=True,
        report_count=3,
    )
    assert score == 95, f"3 reports + disposable email should give 95, got {score}"

    # 4 reports alone = 100 (capped, blocked)
    score = calculate_risk_score_with_reports(
        phone_match=False,
        name_match=False,
        disposable_email=False,
        report_count=4,
    )
    assert score == 100, f"4 reports should give 100, got {score}"


def test_single_report_below_threshold():
    """A single report alone should not trigger blocking."""
    from backend.src.utils.intelligence_shield import calculate_risk_score_with_reports

    score = calculate_risk_score_with_reports(
        phone_match=False,
        name_match=False,
        disposable_email=False,
        report_count=1,
    )
    assert score == 25
    assert score < 80  # Below threshold


def test_zero_reports_no_impact():
    """Zero reports should not affect the base score."""
    from backend.src.utils.intelligence_shield import calculate_risk_score_with_reports

    score = calculate_risk_score_with_reports(
        phone_match=False,
        name_match=False,
        disposable_email=False,
        report_count=0,
    )
    assert score == 0


# ============================================================================
# Duplicate Report Prevention
# ============================================================================

def test_prevent_duplicate_reports():
    """
    Validate that the check_duplicate_report function correctly
    identifies when a reporter has already reported the same user.
    """
    from backend.src.routes.reports import check_duplicate_report

    # Simulate existing reports in DB
    mock_db = MagicMock()

    # Case 1: No existing report -> should return False
    mock_query = MagicMock()
    mock_db.query.return_value = mock_query
    mock_query.filter.return_value = mock_query
    mock_query.first.return_value = None

    result = check_duplicate_report(mock_db, reporter_id=1, reported_id=2)
    assert result is False, "Should return False when no duplicate exists"

    # Case 2: Existing report -> should return True
    mock_query.first.return_value = UserReport(
        reporter_id=1,
        reported_id=2,
        reason_category=ReportCategory.PROFESIONAL_CAMUFLADO,
        description="Already reported",
    )

    result = check_duplicate_report(mock_db, reporter_id=1, reported_id=2)
    assert result is True, "Should return True when duplicate exists"


# ============================================================================
# Self-Report Prevention
# ============================================================================

def test_self_report_validation():
    """A user should not be able to report themselves."""
    from backend.src.routes.reports import validate_report_request

    error = validate_report_request(reporter_id=5, reported_id=5)
    assert error is not None, "Self-report should produce an error"
    assert "yourself" in error.lower() or "mismo" in error.lower()


def test_valid_report_request():
    """A report between two different users should pass validation."""
    from backend.src.routes.reports import validate_report_request

    error = validate_report_request(reporter_id=1, reported_id=2)
    assert error is None, "Valid report should produce no error"


# ============================================================================
# OSINT Re-investigation Trigger
# ============================================================================

@pytest.mark.anyio
async def test_reinvestigation_triggered_at_threshold():
    """
    When a user accumulates 3 or more reports, the system should
    trigger an automatic OSINT re-investigation.
    """
    from backend.src.utils.intelligence_shield import (
        should_trigger_reinvestigation,
    )

    assert should_trigger_reinvestigation(report_count=2) is False
    assert should_trigger_reinvestigation(report_count=3) is True
    assert should_trigger_reinvestigation(report_count=5) is True


# ============================================================================
# Weight Constant: WEIGHT_REPORT
# ============================================================================

def test_report_weight_constant():
    """The report weight constant should be 25."""
    from backend.src.utils.intelligence_shield import WEIGHT_REPORT
    assert WEIGHT_REPORT == 25
