"""
Market Price Analytics — Estimacion de precio por metro cuadrado por zona usando Gemini.

Endpoints:
  POST /ai/market-price   Devuelve precio estimado por m2 para una zona postal
"""
from __future__ import annotations

import json
import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.models.ai_cache import AiMarketPriceCache
from backend.src.services.gemini_service import call_with_fallback, get_client
from backend.src.utils.ai_rate_limit import check_ai_rate_limit
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/ai", tags=["Market Price Analytics"])
logger = logging.getLogger(__name__)

_CACHE_TTL_DAYS = 7


class MarketPriceRequest(BaseModel):
    postal_code: str
    surface_area: float
    property_type: str


class MarketPriceResponse(BaseModel):
    price_per_m2: int
    sample_size: int
    zone_label: str
    confidence: str
    low_density: bool
    message: str | None = None


_LOW_DENSITY_RESPONSE = MarketPriceResponse(
    price_per_m2=0,
    sample_size=0,
    zone_label="Sin datos",
    confidence="LOW",
    low_density=True,
    message="Densidad de mercado baja: No hay datos suficientes",
)


@router.post("/market-price", response_model=MarketPriceResponse)
async def get_market_price(
    body: MarketPriceRequest,
    request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> MarketPriceResponse:
    """
    Estima el precio por metro cuadrado para una zona postal usando Gemini Flash.
    Si la muestra es insuficiente (sample_size < 5) o el analisis falla, devuelve
    low_density=True y nunca extrapola datos ficticios.
    """
    ip = request.client.host if request.client else "unknown"

    # DB cache lookup — keyed by postal_code + property_type, TTL 7 days
    cache_row = db.query(AiMarketPriceCache).filter(
        AiMarketPriceCache.postal_code == body.postal_code,
        AiMarketPriceCache.property_type == body.property_type,
    ).first()
    if cache_row is not None:
        expires = cache_row.expires_at
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        if datetime.now(timezone.utc) < expires:
            logger.info("[MarketPrice] Cache HIT %s / %s", body.postal_code, body.property_type)
            try:
                return MarketPriceResponse(**json.loads(cache_row.response_json))
            except Exception:
                pass  # corrupt row — fall through to Gemini
        else:
            cache_row = None  # expired — signal for upsert below

    await check_ai_rate_limit(current_user.id, "market_price", db, ip)

    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    prompt = f"""Eres un analista inmobiliario especializado en el mercado espanol.

Tu tarea es estimar el precio por metro cuadrado (EUR/m2) para viviendas de tipo
"{body.property_type}" en el codigo postal "{body.postal_code}" basandote
en datos de mercado reales y actuales del mercado espanol.

REGLAS CRITICAS:
1. Si no tienes datos suficientes para esa zona concreta (menos de 5 transacciones
   recientes conocidas), devuelve sample_size=0 y NO extrapoles ningun precio.
2. Si conoces datos reales del mercado para esa zona, proporciona una estimacion
   fundamentada.
3. Responde EXCLUSIVAMENTE con un objeto JSON valido sin markdown ni texto extra.

Formato de respuesta obligatorio:
{{
  "price_per_m2": <entero en EUR/m2, o 0 si no hay datos>,
  "sample_size": <numero de transacciones conocidas en la zona, 0 si desconocido>,
  "zone_label": "<nombre del barrio o zona, o 'Sin datos' si se desconoce>",
  "confidence": "<LOW | MEDIUM | HIGH segun certeza del dato>"
}}

Superficie de referencia de la propiedad: {body.surface_area} m2
Codigo postal: {body.postal_code}
Tipo de propiedad: {body.property_type}"""

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
            logger.warning("market_price: JSON parse failed for postal_code=%s", body.postal_code)
            return _LOW_DENSITY_RESPONSE

        price_per_m2 = int(data.get("price_per_m2") or 0)
        sample_size = int(data.get("sample_size") or 0)
        zone_label = str(data.get("zone_label") or "Sin datos")
        confidence = str(data.get("confidence") or "LOW").upper()

        if confidence not in ("LOW", "MEDIUM", "HIGH"):
            confidence = "LOW"

        # Fiscal truth clause: never show extrapolated values when data is sparse
        if sample_size < 5 or price_per_m2 <= 0:
            return MarketPriceResponse(
                price_per_m2=0,
                sample_size=sample_size,
                zone_label=zone_label,
                confidence="LOW",
                low_density=True,
                message="Densidad de mercado baja: No hay datos suficientes",
            )

        result = MarketPriceResponse(
            price_per_m2=price_per_m2,
            sample_size=sample_size,
            zone_label=zone_label,
            confidence=confidence,
            low_density=False,
            message=None,
        )

        # Persist to DB cache (upsert)
        expires = datetime.now(timezone.utc) + timedelta(days=_CACHE_TTL_DAYS)
        payload = json.dumps(result.model_dump())
        existing = db.query(AiMarketPriceCache).filter(
            AiMarketPriceCache.postal_code == body.postal_code,
            AiMarketPriceCache.property_type == body.property_type,
        ).first()
        if existing:
            existing.response_json = payload
            existing.expires_at = expires
        else:
            db.add(AiMarketPriceCache(
                postal_code=body.postal_code,
                property_type=body.property_type,
                response_json=payload,
                expires_at=expires,
            ))
        db.commit()

        return result

    except HTTPException:
        raise
    except Exception as exc:
        logger.error("market_price: unexpected error postal_code=%s: %s", body.postal_code, exc)
        raise HTTPException(
            status_code=500,
            detail=f"Error inesperado al calcular el precio de mercado: {exc}",
        )
