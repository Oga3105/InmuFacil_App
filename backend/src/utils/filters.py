"""
@Jules - Anti-Real Estate Agency Filter (Detection Logic)
@Shield - Security & Privacy Validation
@Watcher - Observability & Pattern Detection

Heuristic filter to detect and block real estate agency registrations.
Protects InmuFácil's P2P model from professional intermediaries.

Token Consumption Tracking: ~700 tokens for filter implementation
"""

import re
import logging
from typing import Tuple, Optional
from pydantic import EmailStr

logger = logging.getLogger("inmufacil.filters")


# ============================================================================
# @Jules - Known Real Estate Agency Domains
# ============================================================================

KNOWN_AGENCY_DOMAINS = {
    # Major Spanish Real Estate Agencies
    "tecnocasa.es", "tecnocasa.com",
    "redpiso.es", "redpiso.com",
    "remax.es", "remax.com",
    "engel-voelkers.com", "engelvoelkers.com",
    "donpiso.com", "donpiso.es",
    "gilmar.es", "gilmar.com",
    "century21.es", "century21.com",
    "kw.com", "kellerwilliams.es",
    "coldwellbanker.es", "coldwellbanker.com",
    "solvia.es", "solvia.com",
    "aliseda.es", "aliseda.com",
    "altamira.es", "altamira.com",
    "servihabitat.com", "servihabitat.es",
    
    # Real Estate Portals (Professional Accounts)
    "idealista-pro.com", "idealista.com",
    "fotocasa-pro.es", "fotocasa.es",
    "pisos.com", "pisoscom.es",
    "habitaclia.com", "habitaclia.es",
    "yaencontre.com", "yaencontre.es",
    
    # International Agencies
    "sothebysrealty.com",
    "christiesrealestate.com",
    "savills.es", "savills.com",
    "jll.es", "jll.com",
    "cbre.es", "cbre.com",
    
    # Generic Real Estate Domains
    "inmobiliaria.es", "inmobiliaria.com",
    "realestate.es", "realestate.com",
    "propiedades.es", "propiedades.com",
}


# ============================================================================
# @Jules - Professional Keywords Detection
# ============================================================================

PROFESSIONAL_KEYWORDS = {
    # Spanish Professional Terms
    "gestor", "gestora", "gestión",
    "agente", "agencia", "inmobiliaria", "inmobiliario",
    "asesor", "asesora", "asesoría", "asesoramiento",
    "consultor", "consultora", "consultoría",
    "intermediario", "intermediaria",
    "comercial", "broker",
    "promotor", "promotora", "promoción",
    "tasador", "tasadora", "tasación",
    
    # English Professional Terms (for international users)
    "realtor", "real estate", "realestate",
    "property manager", "estate agent",
    "letting agent", "sales agent",
    
    # Company Indicators
    "s.l.", "s.a.", "s.l.u.", "s.c.",
    "ltd", "inc", "llc", "gmbh",
    "inmuebles", "properties",
}


# ============================================================================
# @Jules - Detection Functions
# ============================================================================

def check_email_domain(email: str) -> Tuple[bool, Optional[str]]:
    """
    Check if email domain belongs to a known real estate agency.
    
    Args:
        email: User's email address
        
    Returns:
        Tuple of (is_agency, matched_domain)
        
    @Jules: Domain-based detection logic
    @Shield: Case-insensitive comparison for security
    """
    email_lower = email.lower()
    domain = email_lower.split('@')[-1] if '@' in email_lower else ""
    
    for agency_domain in KNOWN_AGENCY_DOMAINS:
        if domain == agency_domain or domain.endswith('.' + agency_domain):
            logger.warning(f"Agency domain detected: {domain}")
            return True, agency_domain
    
    return False, None


def check_professional_keywords(full_name: str) -> Tuple[bool, list]:
    """
    Check if user's full name contains professional keywords.
    
    Args:
        full_name: User's full name
        
    Returns:
        Tuple of (has_keywords, list_of_matched_keywords)
        
    @Jules: Keyword-based detection logic
    @Shield: Sanitized input to prevent injection
    """
    # Sanitize and normalize input
    name_lower = full_name.lower().strip()
    matched_keywords = []
    
    for keyword in PROFESSIONAL_KEYWORDS:
        # Use word boundary regex to avoid false positives
        # e.g., "Sergio" shouldn't match "gestor"
        pattern = r'\b' + re.escape(keyword) + r'\b'
        if re.search(pattern, name_lower):
            matched_keywords.append(keyword)
    
    if matched_keywords:
        logger.warning(f"Professional keywords detected in name: {matched_keywords}")
    
    return len(matched_keywords) > 0, matched_keywords


# ============================================================================
# @Shield - Main Filter with False Positive Prevention
# ============================================================================

async def validate_user_is_not_agency(
    email: str,
    full_name: str,
) -> Tuple[bool, str]:
    """
    Validates that the registering user is not a real estate agency.

    All new users register as 'particular' by design (ADR-021). The role
    'tercero' is assigned exclusively by superadmin via invitation token, so
    the user_type parameter has been removed from this check.

    Args:
        email: User's email address
        full_name: User's full name

    Returns:
        Tuple of (is_valid, rejection_reason)
        - is_valid: True if user is allowed, False if blocked
        - rejection_reason: Empty string if valid, reason if blocked

    @Shield: Async validation for non-blocking UX
    @Shield: False positive prevention — blocks only on email domain match
    @Watcher: Logs all detection attempts for pattern analysis
    """

    # @Shield: Input sanitization (OWASP)
    email = email.strip().lower()
    full_name = full_name.strip()

    # Check 1: Email domain detection (hard block — agency domain = agency)
    is_agency_domain, matched_domain = check_email_domain(email)
    if is_agency_domain:
        reason = f"Email domain '{matched_domain}' belongs to a known real estate agency"
        logger.warning(f"[BLOCKED] BLOCKED: {reason} | Email: {email}")
        return False, reason

    # Check 2: Professional keywords in name — log only, do not block.
    # Without a user_type signal, a keyword alone is insufficient evidence.
    has_keywords, matched_keywords = check_professional_keywords(full_name)
    if has_keywords:
        logger.info(f"[WARNING]  WARNING: Keywords detected but not blocking (single factor): {matched_keywords}")

    return True, ""


# ============================================================================
# @Watcher - Pattern Detection Helper
# ============================================================================

def log_blocked_attempt(
    email: str,
    full_name: str,
    reason: str,
    ip_address: Optional[str] = None,
    country: Optional[str] = None
):
    """
    Log blocked registration attempt with metadata for pattern analysis.
    
    Args:
        email: Blocked email
        full_name: Blocked name
        reason: Reason for blocking
        ip_address: Optional IP address
        country: Optional country code
        
    @Watcher: Structured logging for security monitoring
    @Watcher: IP and geolocation tracking for spam pattern detection
    
    Token Consumption Tracking: ~100 tokens for logging implementation
    """
    log_data = {
        "event": "PROFESSIONAL_REGISTRATION_BLOCKED",
        "email_domain": email.split('@')[-1] if '@' in email else "unknown",
        "reason": reason,
        "ip_address": ip_address or "unknown",
        "country": country or "unknown",
    }
    
    logger.warning(
        f"[SHIELD]  ESCUDO ANTI-INMO ACTIVATED | "
        f"Domain: {log_data['email_domain']} | "
        f"Reason: {reason} | "
        f"IP: {ip_address or 'N/A'} | "
        f"Country: {country or 'N/A'}"
    )
    
    # @Watcher: This structured log can be parsed for analytics
    logger.info(f"Blocked attempt details: {log_data}")


# ============================================================================
# @Shield - Whitelist Override (Future Enhancement)
# ============================================================================

# Future: Add whitelist functionality for legitimate professional users
# who need access (e.g., verified individual agents, not agencies)
WHITELIST_EMAILS = set()

def is_whitelisted(email: str) -> bool:
    """
    Check if email is in whitelist (future feature).
    
    @Shield: Allows manual override for false positives
    """
    return email.lower() in WHITELIST_EMAILS
