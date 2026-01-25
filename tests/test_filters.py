"""
@Jules - Anti-Agency Filter Tests
@Shield - Security Validation Tests

Test suite for the anti-real estate agency filter.
Validates detection logic, false positive prevention, and edge cases.

Token Consumption Tracking: ~500 tokens for filter tests
"""

import pytest
from backend.filters import (
    check_email_domain,
    check_professional_keywords,
    validate_user_is_not_agency,
    log_blocked_attempt,
)


# ============================================================================
# Email Domain Detection Tests
# ============================================================================

@pytest.mark.asyncio
async def test_block_known_agency_domain():
    """
    Test: Known agency domains are blocked
    
    @Jules: Validates domain detection logic
    """
    # Test major agencies
    test_cases = [
        "agent@tecnocasa.es",
        "info@remax.com",
        "contact@donpiso.es",
        "sales@idealista.com",
    ]
    
    for email in test_cases:
        is_valid, reason = await validate_user_is_not_agency(
            email=email,
            full_name="Juan Pérez"
        )
        assert not is_valid, f"Should block {email}"
        assert "domain" in reason.lower()


@pytest.mark.asyncio
async def test_allow_personal_email_domains():
    """
    Test: Personal email domains are allowed
    
    @Shield: Validates false positive prevention
    """
    # Test common personal email providers
    test_cases = [
        "user@gmail.com",
        "person@hotmail.com",
        "individual@yahoo.es",
        "someone@outlook.com",
    ]
    
    for email in test_cases:
        is_valid, reason = await validate_user_is_not_agency(
            email=email,
            full_name="María García"
        )
        assert is_valid, f"Should allow {email}"
        assert reason == ""


def test_check_email_domain_case_insensitive():
    """
    Test: Domain checking is case-insensitive
    
    @Shield: Security validation
    """
    is_agency, domain = check_email_domain("Agent@TECNOCASA.ES")
    assert is_agency
    assert domain == "tecnocasa.es"


# ============================================================================
# Professional Keywords Detection Tests
# ============================================================================

def test_detect_professional_keywords_in_name():
    """
    Test: Professional keywords are detected in names
    
    @Jules: Validates keyword detection logic
    """
    test_cases = [
        ("Agencia Inmobiliaria López", True, ["agencia", "inmobiliaria"]),
        ("Gestor de Propiedades S.L.", True, ["gestor", "s.l."]),
        ("Asesor Inmobiliario Madrid", True, ["asesor", "inmobiliario"]),
        ("Real Estate Broker Inc", True, ["real estate", "broker", "inc"]),
    ]
    
    for name, should_detect, expected_keywords in test_cases:
        has_keywords, matched = check_professional_keywords(name)
        assert has_keywords == should_detect
        for keyword in expected_keywords:
            assert keyword in matched


def test_no_false_positive_on_similar_names():
    """
    Test: Similar names don't trigger false positives
    
    @Shield: Critical false positive prevention test
    """
    # Names that contain letters from keywords but aren't keywords
    test_cases = [
        "Sergio Torres",  # Contains "ges" but not "gestor"
        "Inmaculada Pérez",  # Contains "inma" but not "inmobiliaria"
        "Agustín García",  # Contains "ag" but not "agente"
    ]
    
    for name in test_cases:
        has_keywords, matched = check_professional_keywords(name)
        assert not has_keywords, f"Should not detect keywords in '{name}', found: {matched}"


# ============================================================================
# Multi-Factor Detection Tests
# ============================================================================

@pytest.mark.asyncio
async def test_block_agency_domain_regardless_of_name():
    """
    Test: Agency domain alone is enough to block
    
    @Jules: Single-factor blocking for obvious cases
    """
    is_valid, reason = await validate_user_is_not_agency(
        email="normal.person@tecnocasa.es",
        full_name="Juan Normal",  # No keywords in name
        user_type="particular"
    )
    assert not is_valid
    assert "tecnocasa.es" in reason


@pytest.mark.asyncio
async def test_allow_keyword_in_name_if_personal_email():
    """
    Test: Keywords in name alone don't block if email is personal
    
    @Shield: False positive prevention - people can have these words in names
    """
    # Someone named "Gestor" (it's a surname in some countries)
    is_valid, reason = await validate_user_is_not_agency(
        email="gestor.family@gmail.com",
        full_name="Pedro Gestor García",
        user_type="particular"
    )
    assert is_valid, "Should allow personal email even with keyword in name"


@pytest.mark.asyncio
async def test_block_professional_type_with_keywords():
    """
    Test: Professional user type + keywords = blocked
    
    @Jules: Multi-factor detection for professional accounts
    """
    is_valid, reason = await validate_user_is_not_agency(
        email="contact@gmail.com",  # Personal domain
        full_name="Agencia Inmobiliaria Madrid",  # But professional name
        user_type="profesional"  # And professional account type
    )
    assert not is_valid
    assert "professional" in reason.lower() or "keywords" in reason.lower()


@pytest.mark.asyncio
async def test_allow_particular_type_with_keywords():
    """
    Test: Particular user type + keywords = allowed (benefit of doubt)
    
    @Shield: False positive prevention for edge cases
    """
    is_valid, reason = await validate_user_is_not_agency(
        email="user@gmail.com",
        full_name="Consultor Pérez",  # Has keyword
        user_type="particular"  # But claims to be particular
    )
    assert is_valid, "Should allow particular users even with keywords (single factor)"


# ============================================================================
# Edge Cases and Security Tests
# ============================================================================

@pytest.mark.asyncio
async def test_handle_email_without_domain():
    """
    Test: Handle malformed emails gracefully
    
    @Shield: Input validation security
    """
    is_valid, reason = await validate_user_is_not_agency(
        email="notanemail",
        full_name="Test User"
    )
    # Should not crash, should allow (benefit of doubt)
    assert is_valid or not is_valid  # Just ensure no exception


@pytest.mark.asyncio
async def test_handle_empty_name():
    """
    Test: Handle empty names gracefully
    
    @Shield: Input validation security
    """
    is_valid, reason = await validate_user_is_not_agency(
        email="test@gmail.com",
        full_name=""
    )
    # Should not crash
    assert is_valid or not is_valid  # Just ensure no exception


@pytest.mark.asyncio
async def test_sanitize_inputs():
    """
    Test: Inputs are sanitized (whitespace, case)
    
    @Shield: OWASP input sanitization
    """
    is_valid, reason = await validate_user_is_not_agency(
        email="  USER@TECNOCASA.ES  ",  # Extra whitespace and uppercase
        full_name="  Test User  "
    )
    assert not is_valid, "Should block even with whitespace and case variations"


# ============================================================================
# Logging Tests
# ============================================================================

def test_log_blocked_attempt_no_crash():
    """
    Test: Logging function doesn't crash
    
    @Watcher: Observability validation
    """
    # Should not raise any exceptions
    log_blocked_attempt(
        email="blocked@agency.com",
        full_name="Agency Name",
        reason="Test reason",
        ip_address="192.168.1.1",
        country="ES"
    )
    
    # Also test with missing optional parameters
    log_blocked_attempt(
        email="blocked@agency.com",
        full_name="Agency Name",
        reason="Test reason"
    )


# ============================================================================
# Real-World Scenario Tests
# ============================================================================

@pytest.mark.asyncio
async def test_real_world_agency_attempts():
    """
    Test: Real-world agency registration attempts are blocked
    
    @Jules: Comprehensive real-world validation
    """
    agency_attempts = [
        {
            "email": "info@tecnocasa.es",
            "name": "Tecnocasa Madrid Centro",
            "type": "profesional"
        },
        {
            "email": "contacto@remax.com",
            "name": "RE/MAX España",
            "type": "profesional"
        },
        {
            "email": "ventas@donpiso.es",
            "name": "Don Piso Asesor Inmobiliario",
            "type": "profesional"
        },
    ]
    
    for attempt in agency_attempts:
        is_valid, reason = await validate_user_is_not_agency(
            email=attempt["email"],
            full_name=attempt["name"],
            user_type=attempt["type"]
        )
        assert not is_valid, f"Should block {attempt['email']}"


@pytest.mark.asyncio
async def test_real_world_legitimate_users():
    """
    Test: Real-world legitimate users are allowed
    
    @Shield: False positive prevention validation
    """
    legitimate_users = [
        {
            "email": "juan.perez@gmail.com",
            "name": "Juan Pérez García",
            "type": "particular"
        },
        {
            "email": "maria.lopez@hotmail.com",
            "name": "María López Fernández",
            "type": "particular"
        },
        {
            "email": "pedro.sanchez@yahoo.es",
            "name": "Pedro Sánchez Martín",
            "type": "particular"
        },
    ]
    
    for user in legitimate_users:
        is_valid, reason = await validate_user_is_not_agency(
            email=user["email"],
            full_name=user["name"],
            user_type=user["type"]
        )
        assert is_valid, f"Should allow legitimate user {user['email']}"
        assert reason == ""
