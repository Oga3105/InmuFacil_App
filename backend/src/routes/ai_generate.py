"""
AI Generate Route — Unified AI content generation endpoint with model selection.

V41 — AI Smart Fallback: supports pro / flash / flash-lite model preference.
The backend selects the model requested by the client; if the model quota is
exhausted (RESOURCE_EXHAUSTED / 429) it propagates a 429 so the Flutter client
can activate its cascading fallback to the next model.

Endpoints:
  POST /ai/generate   Generate content using the specified Gemini model.
"""
from __future__ import annotations

import logging
import os
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.services.gemini_service import GEMINI_MODEL_CHAIN, call_with_fallback, get_client
from backend.src.utils.ai_rate_limit import check_ai_rate_limit
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/ai", tags=["AI"])
logger = logging.getLogger(__name__)

# Map of client-facing preference keys to Gemini model identifiers
MODEL_MAP: dict[str, str] = {
    "pro": "gemini-2.5-pro",
    "flash": "gemini-2.5-flash",
    "flash-lite": "gemini-2.0-flash-lite",
}


class GenerateRequest(BaseModel):
    prompt: str
    model_preference: Literal["pro", "flash", "flash-lite"] = "flash"


class GenerateResponse(BaseModel):
    content: str
    model_used: str


@router.post("/generate", response_model=GenerateResponse)
async def generate_content(
    request: GenerateRequest,
    http_request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> GenerateResponse:
    """
    Generate text content using the requested Gemini model.

    Returns 429 when the model quota is exhausted so the Flutter client can
    cascade to the next model in its priority list (V41 Smart Fallback).
    The prompt is never written to logs to protect user privacy.
    """
    ip = http_request.client.host if http_request.client else "unknown"
    await check_ai_rate_limit(current_user.id, "ai_generate", db, ip)

    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    preferred_model = MODEL_MAP.get(request.model_preference, MODEL_MAP["flash"])

    try:
        content, model_used = call_with_fallback(
            client,
            contents=request.prompt,
            preferred_model=preferred_model,
            model_chain=GEMINI_MODEL_CHAIN,
        )
        return GenerateResponse(content=content, model_used=model_used)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("[AI] Error en generate_content (all models exhausted): %s", repr(exc))
        raise HTTPException(
            status_code=503,
            detail="Error al generar contenido con IA. Intentalo de nuevo.",
        )
