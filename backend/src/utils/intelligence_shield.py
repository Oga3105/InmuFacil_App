"""
Active Intelligence Shield 2.0 -- OSINT-based Professional Detection

Detects real estate agents who register using personal email addresses
(Gmail, Outlook) by analyzing their digital footprint through phone
number and name searches against real estate portals and professional
networks.

Architecture:
- search_osint_sources: Simulated search engine query (prepared for
  Serper/Google Custom Search API integration).
- analyze_with_llm: Sends search snippets to Gemini for professional
  profile classification.
- calculate_risk_score: Weighted scoring algorithm.
- investigate_user_osint: Orchestrator that combines all checks.

Risk Scoring Weights:
- Phone on real estate portal: +40
- Name linked to professional role: +40
- Disposable email domain: +20
- Threshold for blocking: >= 80
"""

import logging
from typing import Dict, Any, Optional

logger = logging.getLogger("inmufacil.intelligence_shield")


# ============================================================================
# Constants
# ============================================================================

RISK_THRESHOLD = 80
WEIGHT_PHONE_PORTAL = 40
WEIGHT_NAME_PROFESSIONAL = 40
WEIGHT_DISPOSABLE_EMAIL = 20
WEIGHT_REPORT = 25

REINVESTIGATION_THRESHOLD = 3

DISPOSABLE_EMAIL_DOMAINS = {
    "tempmail.com",
    "guerrillamail.com",
    "guerrillamail.info",
    "guerrillamail.net",
    "yopmail.com",
    "yopmail.fr",
    "10minutemail.com",
    "throwaway.email",
    "mailinator.com",
    "sharklasers.com",
    "guerrillamailblock.com",
    "grr.la",
    "dispostable.com",
    "trashmail.com",
    "trashmail.net",
    "maildrop.cc",
    "fakeinbox.com",
    "tempail.com",
    "tempr.email",
    "discard.email",
    "getnada.com",
    "mohmal.com",
}


# ============================================================================
# Custom Exception
# ============================================================================

class ProfessionalDetectionException(Exception):
    """
    Raised when the intelligence shield determines with high confidence
    that a user is a professional real estate agent.

    Attributes:
        risk_score: Numeric score (0-100) indicating detection confidence.
        factors: Dict describing which detection vectors triggered.
        reasoning: Human-readable explanation from LLM analysis.
    """

    def __init__(
        self,
        risk_score: int,
        factors: Dict[str, Any],
        reasoning: str,
    ):
        self.risk_score = risk_score
        self.factors = factors
        self.reasoning = reasoning
        super().__init__(
            f"Professional agent detected (score={risk_score}): {reasoning}"
        )


# ============================================================================
# Disposable Email Detection
# ============================================================================

def check_disposable_email(email: str) -> bool:
    """
    Check if the email domain belongs to a known disposable/temporary
    email service.

    Args:
        email: User email address.

    Returns:
        True if the domain is disposable, False otherwise.
    """
    email_lower = email.strip().lower()
    domain = email_lower.split("@")[-1] if "@" in email_lower else ""
    return domain in DISPOSABLE_EMAIL_DOMAINS


# ============================================================================
# Risk Score Calculation
# ============================================================================

def calculate_risk_score(
    phone_match: bool,
    name_match: bool,
    disposable_email: bool,
) -> int:
    """
    Calculate a weighted risk score based on detection factors.

    Args:
        phone_match: Phone found on real estate portals.
        name_match: Name linked to professional real estate roles.
        disposable_email: Email domain is disposable/temporary.

    Returns:
        Integer risk score (0-100).
    """
    score = 0
    if phone_match:
        score += WEIGHT_PHONE_PORTAL
    if name_match:
        score += WEIGHT_NAME_PROFESSIONAL
    if disposable_email:
        score += WEIGHT_DISPOSABLE_EMAIL
    return score


def calculate_risk_score_with_reports(
    phone_match: bool,
    name_match: bool,
    disposable_email: bool,
    report_count: int,
) -> int:
    """
    Calculate risk score including community reports.

    Each verified report from a distinct user adds WEIGHT_REPORT points.
    The total score is capped at 100.

    Args:
        phone_match: Phone found on real estate portals.
        name_match: Name linked to professional real estate roles.
        disposable_email: Email domain is disposable/temporary.
        report_count: Number of distinct user reports against this user.

    Returns:
        Integer risk score (0-100).
    """
    base_score = calculate_risk_score(
        phone_match=phone_match,
        name_match=name_match,
        disposable_email=disposable_email,
    )
    report_score = report_count * WEIGHT_REPORT
    return min(base_score + report_score, 100)


def should_trigger_reinvestigation(report_count: int) -> bool:
    """
    Determine if a user's report count warrants an automatic
    OSINT re-investigation.

    Args:
        report_count: Current number of distinct reports against the user.

    Returns:
        True if re-investigation should be triggered.
    """
    return report_count >= REINVESTIGATION_THRESHOLD


# ============================================================================
# OSINT Search (Simulated -- Ready for Serper/Google API)
# ============================================================================

async def search_osint_sources(
    full_name: str,
    phone: str,
) -> Dict[str, Any]:
    """
    Query search engines for the user's phone number and name to gather
    snippets that may indicate professional real estate activity.

    This is a simulation layer. In production, replace the body with
    actual API calls to Serper (https://serper.dev) or Google Custom
    Search API.

    Args:
        full_name: User's full name.
        phone: User's phone number (E.164 format preferred).

    Returns:
        Dict with keys:
        - phone_snippets: List of search result snippets for the phone.
        - name_snippets: List of search result snippets for the name.
    """
    # PRODUCTION TODO: Replace with actual Serper/Google API call.
    # Example Serper query:
    #   POST https://google.serper.dev/search
    #   {"q": "+34699887766 inmobiliaria OR idealista OR fotocasa"}
    #
    # For now, return empty results (safe default).
    logger.info(
        f"[OSINT] Search requested for name='{full_name}', "
        f"phone='{phone[-4:] if len(phone) >= 4 else '****'}'"
    )
    return {
        "phone_snippets": [],
        "name_snippets": [],
    }


# ============================================================================
# LLM Analysis (Simulated -- Ready for Gemini API)
# ============================================================================

async def analyze_with_llm(
    snippets: Dict[str, Any],
    full_name: str,
) -> Dict[str, Any]:
    """
    Send collected OSINT snippets to an LLM (Gemini) for professional
    profile classification.

    The LLM receives a structured prompt asking it to determine whether
    the search results indicate the person is a professional real estate
    agent, broker, or agency employee.

    This is a simulation layer. In production, replace with actual
    google-genai SDK call.

    Args:
        snippets: Dict with phone_snippets and name_snippets lists.
        full_name: User's full name for context.

    Returns:
        Dict with keys:
        - phone_professional_match: bool
        - name_professional_match: bool
        - confidence: float (0.0 to 1.0)
        - reasoning: str explanation
    """
    # PRODUCTION TODO: Replace with actual Gemini API call.
    # Example prompt:
    #   "Analyze these search results for '{full_name}'.
    #    Phone results: {phone_snippets}
    #    Name results: {name_snippets}
    #    Determine if this person is a professional real estate agent.
    #    Respond with JSON: {phone_professional_match, name_professional_match,
    #    confidence, reasoning}"
    logger.info(f"[LLM] Analysis requested for '{full_name}'")
    return {
        "phone_professional_match": False,
        "name_professional_match": False,
        "confidence": 0.0,
        "reasoning": "Simulated analysis -- no production API configured.",
    }


# ============================================================================
# Main Orchestrator
# ============================================================================

async def investigate_user_osint(
    email: str,
    full_name: str,
    phone: str,
) -> Dict[str, Any]:
    """
    Orchestrate a full OSINT investigation for a registering user.

    Combines search engine results, LLM analysis, and disposable email
    detection into a single risk score with a clear verdict.

    If any external API call fails, the system defaults to score=0
    (allow registration) to avoid blocking legitimate users due to
    infrastructure issues.

    Args:
        email: User's email address.
        full_name: User's full name.
        phone: User's phone number.

    Returns:
        Dict with keys:
        - risk_score: int (0-100)
        - verdict: str ("allowed" or "blocked")
        - blocked: bool
        - factors: Dict of individual detection results
        - reasoning: str from LLM or error description
        - error: str (present only if an API call failed)
    """
    email = email.strip().lower()
    full_name = full_name.strip()
    phone = phone.strip()

    # Check disposable email (local check, no API needed)
    is_disposable = check_disposable_email(email)

    # Attempt OSINT search
    try:
        snippets = await search_osint_sources(
            full_name=full_name,
            phone=phone,
        )
    except Exception as exc:
        logger.error(
            f"[OSINT] Search failed for '{full_name}': {exc}. "
            "Defaulting to safe score=0."
        )
        result = {
            "risk_score": 0,
            "verdict": "allowed",
            "blocked": False,
            "factors": {
                "phone_portal": False,
                "name_professional": False,
                "disposable_email": is_disposable,
            },
            "reasoning": "OSINT search unavailable. Defaulting to allow.",
            "error": str(exc),
        }
        _log_investigation(email, full_name, result)
        return result

    # Attempt LLM analysis
    try:
        llm_result = await analyze_with_llm(
            snippets=snippets,
            full_name=full_name,
        )
        phone_match = llm_result.get("phone_professional_match", False)
        name_match = llm_result.get("name_professional_match", False)
        reasoning = llm_result.get("reasoning", "")
    except Exception as exc:
        logger.error(
            f"[LLM] Analysis failed for '{full_name}': {exc}. "
            "Defaulting to safe score (disposable email check only)."
        )
        phone_match = False
        name_match = False
        reasoning = f"LLM analysis unavailable ({exc}). Partial evaluation only."

        score = calculate_risk_score(
            phone_match=False,
            name_match=False,
            disposable_email=is_disposable,
        )
        result = {
            "risk_score": score,
            "verdict": "allowed" if score < RISK_THRESHOLD else "blocked",
            "blocked": score >= RISK_THRESHOLD,
            "factors": {
                "phone_portal": False,
                "name_professional": False,
                "disposable_email": is_disposable,
            },
            "reasoning": reasoning,
            "error": str(exc),
        }
        _log_investigation(email, full_name, result)
        return result

    # Calculate final score
    score = calculate_risk_score(
        phone_match=phone_match,
        name_match=name_match,
        disposable_email=is_disposable,
    )

    blocked = score >= RISK_THRESHOLD
    verdict = "blocked" if blocked else "allowed"

    result = {
        "risk_score": score,
        "verdict": verdict,
        "blocked": blocked,
        "factors": {
            "phone_portal": phone_match,
            "name_professional": name_match,
            "disposable_email": is_disposable,
        },
        "reasoning": reasoning,
    }

    _log_investigation(email, full_name, result)

    return result


# ============================================================================
# Structured Logging
# ============================================================================

def _log_investigation(
    email: str,
    full_name: str,
    result: Dict[str, Any],
) -> None:
    """
    Emit a structured log entry for the investigation result.

    PII protection: email domain only (not full address), name is logged
    because it is the subject of the OSINT investigation.

    Args:
        email: User email (domain extracted for logging).
        full_name: User full name.
        result: Investigation result dict.
    """
    domain = email.split("@")[-1] if "@" in email else "unknown"
    log_level = logging.WARNING if result["blocked"] else logging.INFO

    logger.log(
        log_level,
        "[INVESTIGATION] verdict=%s score=%d domain=%s factors=%s reasoning='%s'",
        result["verdict"],
        result["risk_score"],
        domain,
        result["factors"],
        result.get("reasoning", "N/A"),
    )
