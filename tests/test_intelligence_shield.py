"""
Active Intelligence Shield 2.0 -- Test Suite

Validates OSINT-based detection of professional real estate agents
who attempt to register using personal email addresses (Gmail, Outlook).

Detection vectors:
- Phone number linked to real estate portals (Idealista, Fotocasa, etc.)
- Name/LinkedIn profile linked to professional roles (Realtor, Broker)
- Disposable/temporary email domains

All external API calls (search engine, LLM) are mocked.
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock

from backend.src.utils.intelligence_shield import (
    investigate_user_osint,
    calculate_risk_score,
    check_disposable_email,
    ProfessionalDetectionException,
    RISK_THRESHOLD,
    WEIGHT_PHONE_PORTAL,
    WEIGHT_NAME_PROFESSIONAL,
    WEIGHT_DISPOSABLE_EMAIL,
)


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def legitimate_user():
    """A regular individual with no professional digital footprint."""
    return {
        "email": "maria.garcia.lopez@gmail.com",
        "full_name": "Maria Garcia Lopez",
        "phone": "+34612345678",
    }


@pytest.fixture
def camouflaged_agent_phone():
    """An agent using a personal email but whose phone appears on portals."""
    return {
        "email": "carlos.vendedor@gmail.com",
        "full_name": "Carlos Martinez",
        "phone": "+34699887766",
    }


@pytest.fixture
def camouflaged_agent_name():
    """An agent using a personal email but whose name links to LinkedIn broker profiles."""
    return {
        "email": "pedro.broker@outlook.com",
        "full_name": "Pedro Sanchez Realtor",
        "phone": "+34611223344",
    }


@pytest.fixture
def disposable_email_user():
    """A user registering with a temporary/disposable email domain."""
    return {
        "email": "test123@tempmail.com",
        "full_name": "Test User",
        "phone": "+34600000000",
    }


# ============================================================================
# Test Case 1: Legitimate User -- Score < 30 (Allowed)
# ============================================================================

@pytest.mark.anyio
async def test_legitimate_user_low_score(legitimate_user):
    """
    A regular individual with a common name and a phone number not found
    on any real estate portal should receive a risk score below the threshold.
    """
    mock_search_results = {
        "phone_snippets": [
            "Telefonica fibra optica contrato residencial",
            "Paginas Blancas resultado no encontrado",
        ],
        "name_snippets": [
            "Maria Garcia Lopez perfil Facebook personal",
            "Maria Garcia Lopez graduada Universidad Complutense 2019",
        ],
    }

    mock_llm_analysis = {
        "phone_professional_match": False,
        "name_professional_match": False,
        "confidence": 0.15,
        "reasoning": "No professional real estate indicators found.",
    }

    with patch(
        "backend.src.utils.intelligence_shield.search_osint_sources",
        new_callable=AsyncMock,
        return_value=mock_search_results,
    ), patch(
        "backend.src.utils.intelligence_shield.analyze_with_llm",
        new_callable=AsyncMock,
        return_value=mock_llm_analysis,
    ):
        result = await investigate_user_osint(
            email=legitimate_user["email"],
            full_name=legitimate_user["full_name"],
            phone=legitimate_user["phone"],
        )

    assert result["risk_score"] < 30, (
        f"Legitimate user score should be < 30, got {result['risk_score']}"
    )
    assert result["verdict"] == "allowed"
    assert result["blocked"] is False


# ============================================================================
# Test Case 2: Camouflaged Agent (Phone on Portals) -- Score > 80 (Blocked)
# ============================================================================

@pytest.mark.anyio
async def test_camouflaged_agent_phone_detected(camouflaged_agent_phone):
    """
    A phone number that appears in search snippets linked to Idealista,
    Fotocasa, or similar real estate portals should trigger a high score.
    """
    mock_search_results = {
        "phone_snippets": [
            "Carlos Martinez - Idealista - Venta de pisos en Madrid centro",
            "Asesoria Inmobiliaria Martinez - Telefono de contacto 699887766",
            "Fotocasa Pro - Agente destacado zona norte Madrid",
        ],
        "name_snippets": [
            "Carlos Martinez agente inmobiliario con 10 anios de experiencia",
        ],
    }

    mock_llm_analysis = {
        "phone_professional_match": True,
        "name_professional_match": True,
        "confidence": 0.95,
        "reasoning": "Phone linked to Idealista listings. Name associated with real estate agency.",
    }

    with patch(
        "backend.src.utils.intelligence_shield.search_osint_sources",
        new_callable=AsyncMock,
        return_value=mock_search_results,
    ), patch(
        "backend.src.utils.intelligence_shield.analyze_with_llm",
        new_callable=AsyncMock,
        return_value=mock_llm_analysis,
    ):
        result = await investigate_user_osint(
            email=camouflaged_agent_phone["email"],
            full_name=camouflaged_agent_phone["full_name"],
            phone=camouflaged_agent_phone["phone"],
        )

    assert result["risk_score"] >= RISK_THRESHOLD, (
        f"Agent phone+name score should be >= {RISK_THRESHOLD}, got {result['risk_score']}"
    )
    assert result["verdict"] == "blocked"
    assert result["blocked"] is True


# ============================================================================
# Test Case 3: Camouflaged Agent (Name/LinkedIn + Disposable Email) -- Blocked
# ============================================================================

@pytest.mark.anyio
async def test_camouflaged_agent_name_linkedin(camouflaged_agent_name):
    """
    A name associated with 'Realtor', 'Broker', or real estate professional
    profiles on LinkedIn, combined with a disposable email, should reach
    the blocking threshold (name=40 + disposable=20 = 60, plus phone if
    also matched). Here we test name + phone both matching via LLM.
    """
    mock_search_results = {
        "phone_snippets": [
            "Pedro Sanchez Realtor contacto directo 611223344 - Idealista",
        ],
        "name_snippets": [
            "Pedro Sanchez Realtor - LinkedIn - Senior Real Estate Broker at RE/MAX",
            "Pedro Sanchez - Broker inmobiliario certificado - Idealista Pro",
            "Directorio de agentes inmobiliarios - Pedro Sanchez, Madrid",
        ],
    }

    mock_llm_analysis = {
        "phone_professional_match": True,
        "name_professional_match": True,
        "confidence": 0.92,
        "reasoning": "LinkedIn profile identifies subject as Senior Real Estate Broker. Phone found on Idealista.",
    }

    with patch(
        "backend.src.utils.intelligence_shield.search_osint_sources",
        new_callable=AsyncMock,
        return_value=mock_search_results,
    ), patch(
        "backend.src.utils.intelligence_shield.analyze_with_llm",
        new_callable=AsyncMock,
        return_value=mock_llm_analysis,
    ):
        result = await investigate_user_osint(
            email=camouflaged_agent_name["email"],
            full_name=camouflaged_agent_name["full_name"],
            phone=camouflaged_agent_name["phone"],
        )

    assert result["risk_score"] >= RISK_THRESHOLD, (
        f"Agent name+phone score should be >= {RISK_THRESHOLD}, got {result['risk_score']}"
    )
    assert result["verdict"] == "blocked"
    assert result["blocked"] is True


# ============================================================================
# Test Case 4: Disposable Email -- +20 Risk Score Increment
# ============================================================================

@pytest.mark.anyio
async def test_disposable_email_increases_score(disposable_email_user):
    """
    A disposable/temporary email domain should add +20 to the risk score,
    regardless of other factors.
    """
    mock_search_results = {
        "phone_snippets": [],
        "name_snippets": [],
    }

    mock_llm_analysis = {
        "phone_professional_match": False,
        "name_professional_match": False,
        "confidence": 0.10,
        "reasoning": "No professional indicators found.",
    }

    with patch(
        "backend.src.utils.intelligence_shield.search_osint_sources",
        new_callable=AsyncMock,
        return_value=mock_search_results,
    ), patch(
        "backend.src.utils.intelligence_shield.analyze_with_llm",
        new_callable=AsyncMock,
        return_value=mock_llm_analysis,
    ):
        result = await investigate_user_osint(
            email=disposable_email_user["email"],
            full_name=disposable_email_user["full_name"],
            phone=disposable_email_user["phone"],
        )

    assert result["risk_score"] >= WEIGHT_DISPOSABLE_EMAIL, (
        f"Disposable email should add at least {WEIGHT_DISPOSABLE_EMAIL} points, "
        f"got total score {result['risk_score']}"
    )
    assert result["factors"]["disposable_email"] is True


def test_check_disposable_email_known_domains():
    """Disposable email detection should flag known throwaway domains."""
    disposable_domains = [
        "tempmail.com", "guerrillamail.com", "yopmail.com",
        "10minutemail.com", "throwaway.email", "mailinator.com",
    ]
    for domain in disposable_domains:
        email = f"user@{domain}"
        assert check_disposable_email(email) is True, (
            f"{domain} should be detected as disposable"
        )


def test_check_disposable_email_legitimate_domains():
    """Legitimate domains should not be flagged as disposable."""
    legit_domains = [
        "gmail.com", "outlook.com", "yahoo.es", "hotmail.com",
        "icloud.com", "protonmail.com",
    ]
    for domain in legit_domains:
        email = f"user@{domain}"
        assert check_disposable_email(email) is False, (
            f"{domain} should NOT be detected as disposable"
        )


# ============================================================================
# Test Case 5: API Failure Graceful Fallback
# ============================================================================

@pytest.mark.anyio
async def test_api_failure_returns_safe_default(legitimate_user):
    """
    If external APIs (search, LLM) fail, the system should not block
    the registration. Default to score=0 and allow.
    """
    with patch(
        "backend.src.utils.intelligence_shield.search_osint_sources",
        new_callable=AsyncMock,
        side_effect=Exception("Search API unreachable"),
    ):
        result = await investigate_user_osint(
            email=legitimate_user["email"],
            full_name=legitimate_user["full_name"],
            phone=legitimate_user["phone"],
        )

    assert result["risk_score"] == 0
    assert result["verdict"] == "allowed"
    assert result["blocked"] is False
    assert "error" in result


@pytest.mark.anyio
async def test_llm_failure_returns_safe_default(legitimate_user):
    """
    If the LLM analysis fails after search succeeds, fall back to
    score based only on disposable email check (if applicable).
    """
    mock_search_results = {
        "phone_snippets": ["Some result"],
        "name_snippets": ["Some result"],
    }

    with patch(
        "backend.src.utils.intelligence_shield.search_osint_sources",
        new_callable=AsyncMock,
        return_value=mock_search_results,
    ), patch(
        "backend.src.utils.intelligence_shield.analyze_with_llm",
        new_callable=AsyncMock,
        side_effect=Exception("Gemini API quota exceeded"),
    ):
        result = await investigate_user_osint(
            email=legitimate_user["email"],
            full_name=legitimate_user["full_name"],
            phone=legitimate_user["phone"],
        )

    # Should not block -- LLM failure should not penalize the user
    assert result["blocked"] is False
    assert result["verdict"] == "allowed"


# ============================================================================
# Test Case 6: Risk Score Calculation Unit Tests
# ============================================================================

def test_calculate_risk_score_no_factors():
    """No factors detected should produce score 0."""
    score = calculate_risk_score(
        phone_match=False,
        name_match=False,
        disposable_email=False,
    )
    assert score == 0


def test_calculate_risk_score_phone_only():
    """Phone match alone should produce WEIGHT_PHONE_PORTAL."""
    score = calculate_risk_score(
        phone_match=True,
        name_match=False,
        disposable_email=False,
    )
    assert score == WEIGHT_PHONE_PORTAL


def test_calculate_risk_score_name_only():
    """Name match alone should produce WEIGHT_NAME_PROFESSIONAL."""
    score = calculate_risk_score(
        phone_match=False,
        name_match=True,
        disposable_email=False,
    )
    assert score == WEIGHT_NAME_PROFESSIONAL


def test_calculate_risk_score_all_factors():
    """All factors combined should produce the maximum score."""
    score = calculate_risk_score(
        phone_match=True,
        name_match=True,
        disposable_email=True,
    )
    expected = WEIGHT_PHONE_PORTAL + WEIGHT_NAME_PROFESSIONAL + WEIGHT_DISPOSABLE_EMAIL
    assert score == expected


def test_calculate_risk_score_phone_plus_email():
    """Phone + disposable email should reach threshold."""
    score = calculate_risk_score(
        phone_match=True,
        name_match=False,
        disposable_email=True,
    )
    assert score == WEIGHT_PHONE_PORTAL + WEIGHT_DISPOSABLE_EMAIL


# ============================================================================
# Test Case 7: ProfessionalDetectionException
# ============================================================================

def test_professional_detection_exception_attributes():
    """The custom exception should carry risk_score, factors, and reasoning."""
    exc = ProfessionalDetectionException(
        risk_score=85,
        factors={"phone_portal": True, "name_professional": True},
        reasoning="Phone on Idealista + LinkedIn Broker profile",
    )
    assert exc.risk_score == 85
    assert exc.factors["phone_portal"] is True
    assert "Idealista" in exc.reasoning
    assert str(exc)  # Should have a human-readable string representation


# ============================================================================
# Test Case 8: Structured Logging Verification
# ============================================================================

@pytest.mark.anyio
async def test_investigation_produces_structured_log(legitimate_user, caplog):
    """Every investigation should produce a structured log entry."""
    mock_search_results = {"phone_snippets": [], "name_snippets": []}
    mock_llm_analysis = {
        "phone_professional_match": False,
        "name_professional_match": False,
        "confidence": 0.05,
        "reasoning": "Clean profile.",
    }

    with patch(
        "backend.src.utils.intelligence_shield.search_osint_sources",
        new_callable=AsyncMock,
        return_value=mock_search_results,
    ), patch(
        "backend.src.utils.intelligence_shield.analyze_with_llm",
        new_callable=AsyncMock,
        return_value=mock_llm_analysis,
    ):
        import logging
        with caplog.at_level(logging.INFO, logger="inmufacil.intelligence_shield"):
            result = await investigate_user_osint(
                email=legitimate_user["email"],
                full_name=legitimate_user["full_name"],
                phone=legitimate_user["phone"],
            )

    assert any("INVESTIGATION" in record.message for record in caplog.records), (
        "Should produce a log entry containing 'INVESTIGATION'"
    )
