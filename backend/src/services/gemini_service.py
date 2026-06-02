"""
Gemini AI — Centralized Client with Model Fallback Chain.

All routes and services must use this module instead of calling
google.genai directly. This ensures automatic model rotation when
quota is exhausted or a model is unavailable.

Usage:
    from backend.src.services.gemini_service import call_with_fallback, get_client

    client = get_client()
    text, model_used = call_with_fallback(client, contents=[prompt])
"""
from __future__ import annotations

import logging
import os
from typing import Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Model chains — ordered from most preferred to last resort.
# Both chains support multimodal (vision) inputs.
# ---------------------------------------------------------------------------

# General-purpose chain (text and multimodal tasks)
GEMINI_MODEL_CHAIN: list[str] = [
    "gemini-2.5-flash",
    "gemini-2.0-flash",
    "gemini-2.0-flash-lite",
    "gemini-1.5-flash",
]

# KYC/OCR chain — flash for accuracy, lite as fallback
GEMINI_KYC_MODEL_CHAIN: list[str] = [
    "gemini-2.0-flash",
    "gemini-2.5-flash",
    "gemini-1.5-flash",
]


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def get_client(api_key: Optional[str] = None):
    """
    Return an initialized Gemini client.
    Raises RuntimeError if google-genai is not installed or API key is missing.
    """
    try:
        from google import genai  # noqa: PLC0415
    except ImportError as exc:
        raise RuntimeError(
            "google-genai not installed. Rebuild the backend Docker image: "
            "docker-compose build --no-cache backend"
        ) from exc

    key = api_key or os.getenv("GEMINI_API_KEY", "")
    if not key:
        raise RuntimeError("GEMINI_API_KEY not set in environment")

    return genai.Client(api_key=key)


def call_with_fallback(
    client,
    contents: list,
    preferred_model: Optional[str] = None,
    model_chain: Optional[list[str]] = None,
) -> tuple[str, str]:
    """
    Call Gemini generate_content with automatic model fallback.

    Tries models in order: preferred_model first (if given), then the rest of
    model_chain. Advances to the next model on RESOURCE_EXHAUSTED (quota) or
    NOT_FOUND (model unavailable). Re-raises immediately for any other error.

    Args:
        client:          Gemini client returned by get_client().
        contents:        Contents list passed to generate_content (text, Parts, etc.).
        preferred_model: Model to try first. If None, uses first model in chain.
        model_chain:     Ordered fallback list. Defaults to GEMINI_MODEL_CHAIN.

    Returns:
        (response_text, model_used) — text is stripped, never None.

    Raises:
        Exception: when all models fail for non-skippable reasons, or all exhausted.
    """
    chain = _build_chain(preferred_model, model_chain or GEMINI_MODEL_CHAIN)
    last_skippable: Optional[Exception] = None

    for model in chain:
        try:
            response = client.models.generate_content(
                model=model,
                contents=contents,
            )
            if last_skippable is not None:
                logger.info("[Gemini] Fallback successful — model used: %s", model)
            return (response.text or "").strip(), model
        except Exception as exc:  # noqa: BLE001
            if _is_skippable(exc):
                reason = "QUOTA" if _is_quota(exc) else "NOT_FOUND"
                logger.warning(
                    "[Gemini] Model %s skipped (%s), trying next in chain.",
                    model,
                    reason,
                )
                last_skippable = exc
                continue
            raise  # Non-quota / non-not-found: propagate immediately

    raise last_skippable or RuntimeError(
        "All Gemini models in fallback chain are exhausted or unavailable."
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _build_chain(preferred: Optional[str], chain: list[str]) -> list[str]:
    """Return chain starting with preferred model (deduped)."""
    if not preferred or preferred == chain[0]:
        return chain
    return [preferred] + [m for m in chain if m != preferred]


def _is_quota(exc: Exception) -> bool:
    s = str(exc)
    return "429" in s or "RESOURCE_EXHAUSTED" in s or "quota" in s.lower()


def _is_model_not_found(exc: Exception) -> bool:
    s = str(exc)
    return "NOT_FOUND" in s or ("404" in s and ("model" in s.lower() or "NOT_FOUND" in s))


def _is_permission_denied(exc: Exception) -> bool:
    s = str(exc)
    return "PERMISSION_DENIED" in s or "403" in s or "permission" in s.lower()


def _is_unavailable(exc: Exception) -> bool:
    s = str(exc)
    return "UNAVAILABLE" in s or "overloaded" in s.lower() or "high demand" in s.lower()


def _is_skippable(exc: Exception) -> bool:
    return (
        _is_quota(exc)
        or _is_model_not_found(exc)
        or _is_permission_denied(exc)
        or _is_unavailable(exc)
    )
