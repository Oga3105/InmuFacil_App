"""
Price Validator — Validacion de precio de oferta con Gemini.

Endpoints:
  POST /ai/validate-price   Veredicto sobre si una oferta es justa respecto al precio pedido
"""
from __future__ import annotations

import hashlib
import json
import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.models.ai_cache import AiPriceValidationCache
from backend.src.services.gemini_service import call_with_fallback, get_client
from backend.src.utils.ai_rate_limit import check_ai_rate_limit
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/ai", tags=["Price Validator"])
logger = logging.getLogger(__name__)

_CACHE_TTL_HOURS = 24


def _cache_key(postal_code: str, pct_diff: float, asking_price_per_m2: float) -> str:
    """
    64-char hex key from postal_code + rounded pct_diff band (5% steps)
    + rounded asking_price_per_m2 band (500 EUR steps).
    Offers that are essentially equivalent from a zone/price perspective
    will share a cached verdict.
    """
    pct_band = round(pct_diff / 5) * 5
    price_band = round(asking_price_per_m2 / 500) * 500
    raw = f"{postal_code}|{pct_band}|{price_band}"
    return hashlib.sha256(raw.encode()).hexdigest()

_VALID_VERDICTS = {"JUSTO", "ALGO_ALTO", "ALGO_BAJO", "MUY_ALTO", "MUY_BAJO"}
_VALID_CONFIDENCES = {"LOW", "MEDIUM", "HIGH"}
_VALID_RISKS = {"LOW", "MEDIUM", "HIGH"}


class PriceValidationRequest(BaseModel):
    offer_price: int = Field(..., gt=0)
    asking_price: int = Field(..., gt=0)
    postal_code: str
    surface_area: float = Field(..., gt=0)


class PriceValidationResponse(BaseModel):
    verdict: str
    confidence: str
    reasoning: str
    risk_level: str


@router.post("/validate-price", response_model=PriceValidationResponse)
async def validate_price(
    body: PriceValidationRequest,
    request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> PriceValidationResponse:
    """
    Analiza si una oferta de compra es justa en relacion al precio de venta
    y al contexto del mercado de la zona usando Gemini Flash.
    """
    ip = request.client.host if request.client else "unknown"
    pct_diff = ((body.offer_price - body.asking_price) / body.asking_price) * 100
    asking_per_m2 = body.asking_price / body.surface_area
    ck = _cache_key(body.postal_code, pct_diff, asking_per_m2)

    # DB cache lookup — TTL 24h
    cache_row = db.query(AiPriceValidationCache).filter(
        AiPriceValidationCache.cache_key == ck,
    ).first()
    if cache_row is not None:
        expires = cache_row.expires_at
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        if datetime.now(timezone.utc) < expires:
            logger.info("[PriceValidator] Cache HIT key=%s", ck[:12])
            try:
                return PriceValidationResponse(**json.loads(cache_row.response_json))
            except Exception:
                pass  # corrupt row — fall through
        else:
            cache_row = None  # expired

    await check_ai_rate_limit(current_user.id, "price_validator", db, ip)

    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    prompt = f"""Eres un analista inmobiliario senior especializado en el mercado espanol.

Analiza si el precio de oferta es justo en relacion al precio de venta solicitado
y al contexto del mercado de la zona.

DATOS DE LA OPERACION:
- Precio de venta solicitado: {body.asking_price:,} EUR
- Precio ofertado por el comprador: {body.offer_price:,} EUR
- Diferencia porcentual: {pct_diff:+.1f}%
- Superficie: {body.surface_area} m2
- Codigo postal de la propiedad: {body.postal_code}

CRITERIOS DE EVALUACION:
- JUSTO: oferta dentro del +/-5% del precio de mercado razonable
- ALGO_ALTO: oferta o precio entre +5% y +15% sobre mercado
- ALGO_BAJO: oferta o precio entre -5% y -15% bajo mercado
- MUY_ALTO: oferta o precio mas de +15% sobre mercado
- MUY_BAJO: oferta o precio mas de -15% bajo mercado

Considera el contexto del codigo postal "{body.postal_code}" para evaluar si el
precio de venta en si mismo es razonable antes de emitir el veredicto sobre la oferta.

REGLAS:
1. Responde EXCLUSIVAMENTE con un objeto JSON valido sin markdown ni texto extra.
2. El razonamiento debe ser conciso (maximo 3 frases), profesional y en espanol.
3. Nunca menciones datos inventados ni empresas concretas.

Formato de respuesta obligatorio:
{{
  "verdict": "<JUSTO | ALGO_ALTO | ALGO_BAJO | MUY_ALTO | MUY_BAJO>",
  "confidence": "<LOW | MEDIUM | HIGH>",
  "reasoning": "<explicacion breve en espanol, maximo 3 frases>",
  "risk_level": "<LOW | MEDIUM | HIGH>"
}}"""

    try:
        raw, _ = call_with_fallback(client, contents=[prompt], preferred_model="gemini-2.5-flash")

        # Strip markdown fences if present
        if raw.startswith("```"):
            lines = raw.splitlines()
            raw = "\n".join(
                line for line in lines if not line.startswith("```")
            ).strip()

        try:
            data = json.loads(raw)
        except (json.JSONDecodeError, ValueError):
            logger.warning(
                "price_validator: JSON parse failed for postal_code=%s", body.postal_code
            )
            raise HTTPException(
                status_code=503,
                detail="La IA no pudo generar un analisis en este momento. Intentalo de nuevo.",
            )

        verdict = str(data.get("verdict") or "JUSTO").upper()
        confidence = str(data.get("confidence") or "LOW").upper()
        reasoning = str(data.get("reasoning") or "").strip()
        risk_level = str(data.get("risk_level") or "MEDIUM").upper()

        # Sanitise enum values
        if verdict not in _VALID_VERDICTS:
            verdict = "JUSTO"
        if confidence not in _VALID_CONFIDENCES:
            confidence = "LOW"
        if risk_level not in _VALID_RISKS:
            risk_level = "MEDIUM"

        result = PriceValidationResponse(
            verdict=verdict,
            confidence=confidence,
            reasoning=reasoning,
            risk_level=risk_level,
        )

        # Persist to DB cache (upsert)
        expires = datetime.now(timezone.utc) + timedelta(hours=_CACHE_TTL_HOURS)
        payload = json.dumps(result.model_dump())
        existing = db.query(AiPriceValidationCache).filter(
            AiPriceValidationCache.cache_key == ck,
        ).first()
        if existing:
            existing.response_json = payload
            existing.expires_at = expires
        else:
            db.add(AiPriceValidationCache(
                cache_key=ck,
                response_json=payload,
                expires_at=expires,
            ))
        db.commit()

        return result

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "price_validator: unexpected error postal_code=%s: %s", body.postal_code, exc
        )
        raise HTTPException(
            status_code=500,
            detail=f"Error inesperado al validar el precio: {exc}",
        )
