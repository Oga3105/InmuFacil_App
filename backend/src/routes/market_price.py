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
    city: str | None = None
    province: str | None = None
    street: str | None = None
    latitude: float | None = None
    longitude: float | None = None


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

    # Build location context — more data = more precise neighborhood identification
    location_lines: list[str] = [f"- Codigo postal: {body.postal_code}"]
    if body.city:
        location_lines.append(f"- Ciudad: {body.city}")
    if body.province and body.province != body.city:
        location_lines.append(f"- Provincia: {body.province}")
    if body.street:
        location_lines.append(f"- Calle/Via: {body.street}")
    if body.latitude is not None and body.longitude is not None:
        location_lines.append(f"- Coordenadas GPS: {body.latitude:.6f}, {body.longitude:.6f}")
    location_block = "\n".join(location_lines)

    prompt = f"""Eres un analista inmobiliario especializado en el mercado espanol.

Tu tarea es estimar el precio por metro cuadrado (EUR/m2) para viviendas de tipo
"{body.property_type}" en la ubicacion exacta indicada, basandote en datos de
mercado reales y actuales del mercado espanol.

DATOS DE UBICACION (usa TODOS para identificar el barrio exacto):
{location_block}
- Superficie de referencia: {body.surface_area} m2
- Tipo de propiedad: {body.property_type}

INSTRUCCIONES CRITICAS:
1. Usa la calle y las coordenadas GPS para identificar el barrio EXACTO, no el mas
   conocido del codigo postal. Un mismo CP puede abarcar varios barrios con precios
   muy distintos.
2. Si no tienes datos suficientes para esa ubicacion concreta (menos de 5
   transacciones recientes conocidas), devuelve sample_size=0 y NO extrapoles.
3. El campo "zone_label" debe ser el nombre del barrio especifico al que pertenece
   la calle indicada, NO el barrio mas famoso del CP.
4. Responde EXCLUSIVAMENTE con un objeto JSON valido sin markdown ni texto extra.

Formato de respuesta obligatorio:
{{
  "price_per_m2": <entero en EUR/m2, o 0 si no hay datos>,
  "sample_size": <numero de transacciones conocidas en la zona, 0 si desconocido>,
  "zone_label": "<nombre del barrio exacto segun la calle/coordenadas, no el CP>",
  "confidence": "<LOW | MEDIUM | HIGH segun certeza del dato>"
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
