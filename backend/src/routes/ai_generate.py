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

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from backend.src.models import User
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
    current_user: User = Depends(get_current_active_user),
) -> GenerateResponse:
    """
    Generate text content using the requested Gemini model.

    Returns 429 when the model quota is exhausted so the Flutter client can
    cascade to the next model in its priority list (V41 Smart Fallback).
    The prompt is never written to logs to protect user privacy.
    """
    try:
        from google import genai  # type: ignore[import]
    except ImportError:
        raise HTTPException(
            status_code=503,
            detail="Servicio de IA no disponible. Contacta con soporte.",
        )

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="Servicio de IA no configurado.",
        )

    model_id = MODEL_MAP.get(request.model_preference, MODEL_MAP["flash"])

    try:
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model=model_id,
            contents=request.prompt,
        )
        return GenerateResponse(
            content=(response.text or "").strip(),
            model_used=model_id,
        )
    except HTTPException:
        raise
    except Exception as exc:
        error_repr = repr(exc)
        if "429" in error_repr or "RESOURCE_EXHAUSTED" in error_repr:
            # Log only the model name — never the prompt content
            logger.warning(
                "[AI] Modelo %s agotado. Conmutando al siguiente.",
                model_id,
            )
            raise HTTPException(
                status_code=429,
                detail="Cuota del modelo agotada. Intentando con el siguiente.",
            )
        logger.error("[AI] Error en generate_content: %s", error_repr)
        raise HTTPException(
            status_code=503,
            detail="Error al generar contenido con IA. Intentalo de nuevo.",
        )
