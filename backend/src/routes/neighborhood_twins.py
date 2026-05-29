"""
Neighborhood Twins -- Encuentra zonas similares a un codigo postal dado.

Endpoints:
  POST /ai/neighborhood-twins  Devuelve lista de barrios gemelos con puntuacion de similitud
"""
from __future__ import annotations

import hashlib
import json
import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from sqlalchemy import func

from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.models.ai_cache import AiNeighborhoodTwinsCache
from backend.src.models.properties import Property as PropertyModel
from backend.src.models.enums import PropertyStatus
from backend.src.services.gemini_service import call_with_fallback, get_client
from backend.src.utils.ai_rate_limit import check_ai_rate_limit
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/ai", tags=["Neighborhood Twins"])
logger = logging.getLogger(__name__)

_CACHE_TTL_DAYS = 30


def _cache_key(body: "NeighborhoodTwinsRequest") -> str:
    """
    Stable 64-char hex key from postal_code + sorted lifestyle filters.
    context_cities and max_results are excluded (viewport/request-specific).
    """
    parts = [
        body.postal_code,
        body.city or "",
        body.lifestyle_pace or "",
        body.work_style or "",
        body.mobility_style or "",
        body.green_needs or "",
        body.budget_range or "",
    ]
    raw = "|".join(parts)
    return hashlib.sha256(raw.encode()).hexdigest()


class NeighborhoodTwinsRequest(BaseModel):
    postal_code: str
    city: str | None = None
    # Cities currently visible/active in the frontend (search location or map viewport).
    # When provided, Gemini is constrained to suggest only within these cities.
    context_cities: list[str] | None = None
    lifestyle_pace: str | None = None
    work_style: str | None = None
    mobility_style: str | None = None
    green_needs: str | None = None
    budget_range: str | None = None
    max_results: int = 5


class NeighborhoodTwin(BaseModel):
    postal_code: str
    neighborhood_name: str
    city: str
    similarity_score: int
    avg_price_sqm: int | None
    key_similarities: list[str]
    key_differences: list[str]
    vibe: str
    # Stock enrichment — properties available on InmuFacil in this twin zone
    available_count: int = 0
    price_from: int | None = None
    price_to: int | None = None


class NeighborhoodTwinsResponse(BaseModel):
    source_postal_code: str
    twins: list[NeighborhoodTwin]
    low_data: bool
    disclaimer: str


_DISCLAIMER = (
    "Zonas similares calculadas por IA basandose en patrones urbanisticos y de estilo de vida. "
    "Los precios son estimaciones de mercado. Verifica disponibilidad de vivienda en cada zona."
)


@router.post("/neighborhood-twins", response_model=NeighborhoodTwinsResponse)
async def get_neighborhood_twins(
    body: NeighborhoodTwinsRequest,
    request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> NeighborhoodTwinsResponse:
    """
    Encuentra barrios gemelos al codigo postal dado, filtrados por perfil de lifestyle.
    """
    ip = request.client.host if request.client else "unknown"
    ck = _cache_key(body)

    # DB cache lookup — raw Gemini twins list (stock enrichment is always live)
    cache_row = db.query(AiNeighborhoodTwinsCache).filter(
        AiNeighborhoodTwinsCache.cache_key == ck,
    ).first()
    cached_twins: list[dict] | None = None
    if cache_row is not None:
        expires = cache_row.expires_at
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        if datetime.now(timezone.utc) < expires:
            logger.info("[NeighborhoodTwins] Cache HIT key=%s", ck[:12])
            try:
                cached_twins = json.loads(cache_row.response_json)
            except Exception:
                pass  # corrupt row — fall through
        else:
            cache_row = None  # expired

    if cached_twins is None:
        await check_ai_rate_limit(current_user.id, "neighborhood_twins", db, ip)

    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    lifestyle_context = ""
    if body.lifestyle_pace:
        pace_label = "Centro vibrante" if body.lifestyle_pace == "vibrant_center" else "Periferia tranquila"
        lifestyle_context += f"\n- Ritmo de vida: {pace_label}"
    if body.work_style:
        work_label = "Oficina" if body.work_style == "daily_office" else "Teletrabajo"
        lifestyle_context += f"\n- Trabajo: {work_label}"
    if body.mobility_style:
        mob_label = "Transporte publico" if body.mobility_style == "public_transport" else "Vehiculo privado"
        lifestyle_context += f"\n- Movilidad: {mob_label}"
    if body.green_needs:
        green_label = "Zonas verdes" if body.green_needs == "needs_green" else "Servicios urbanos"
        lifestyle_context += f"\n- Preferencia: {green_label}"
    if body.budget_range:
        lifestyle_context += f"\n- Presupuesto: {body.budget_range}"

    city_context = f" en {body.city}" if body.city else " en Espana"

    # Build city restriction when the frontend provides context cities
    city_restriction = ""
    # Ask for more candidates so we have room to filter after DB cross-check
    gemini_max = max(body.max_results * 3, 15)
    if body.context_cities:
        cities_str = ", ".join(body.context_cities)
        city_restriction = (
            f"\nRESTRICCION OBLIGATORIA: Solo puedes sugerir barrios DENTRO de estas ciudades: {cities_str}. "
            "No sugieras barrios de otras ciudades. "
            "Si no hay suficiente variedad, devuelve los que haya aunque sean pocos."
        )

    prompt = f"""Eres un experto en urbanismo espanol. Encuentra los {gemini_max} barrios mas similares al codigo postal {body.postal_code}{city_context}.
Perfil de usuario:{lifestyle_context if lifestyle_context else " generico"}{city_restriction}

REGLAS: Solo barrios REALES en Espana. similarity_score 0-100. avg_price_sqm en euros/m2 o null.
Responde SOLO con JSON valido:
{{
  "low_data": false,
  "twins": [
    {{
      "postal_code": "28001",
      "neighborhood_name": "Ejemplo",
      "city": "Madrid",
      "similarity_score": 85,
      "avg_price_sqm": 4200,
      "key_similarities": ["Factor 1", "Factor 2"],
      "key_differences": ["Diferencia 1"],
      "vibe": "Barrio tranquilo con buenos accesos"
    }}
  ]
}}"""

    try:
        if cached_twins is None:
            raw, _ = call_with_fallback(client, contents=[prompt], preferred_model="gemini-2.5-flash")

            if raw.startswith("```"):
                lines = raw.splitlines()
                raw = "\n".join(line for line in lines if not line.startswith("```")).strip()

            try:
                data = json.loads(raw)
            except (json.JSONDecodeError, ValueError):
                logger.warning("neighborhood_twins: JSON parse failed for postal_code=%s", body.postal_code)
                return NeighborhoodTwinsResponse(source_postal_code=body.postal_code, twins=[], low_data=True, disclaimer=_DISCLAIMER)

            if bool(data.get("low_data", False)):
                return NeighborhoodTwinsResponse(source_postal_code=body.postal_code, twins=[], low_data=True, disclaimer=_DISCLAIMER)

            cached_twins = data.get("twins") or []

            # Persist raw twins list to DB cache (upsert)
            expires = datetime.now(timezone.utc) + timedelta(days=_CACHE_TTL_DAYS)
            payload = json.dumps(cached_twins)
            existing = db.query(AiNeighborhoodTwinsCache).filter(
                AiNeighborhoodTwinsCache.cache_key == ck,
            ).first()
            if existing:
                existing.response_json = payload
                existing.expires_at = expires
            else:
                db.add(AiNeighborhoodTwinsCache(
                    cache_key=ck,
                    response_json=payload,
                    expires_at=expires,
                ))
            db.commit()

        twins: list[NeighborhoodTwin] = []
        for item in (cached_twins or []):
            try:
                twins.append(NeighborhoodTwin(
                    postal_code=str(item.get("postal_code") or ""),
                    neighborhood_name=str(item.get("neighborhood_name") or ""),
                    city=str(item.get("city") or ""),
                    similarity_score=max(0, min(100, int(item.get("similarity_score") or 0))),
                    avg_price_sqm=int(item["avg_price_sqm"]) if item.get("avg_price_sqm") else None,
                    key_similarities=[str(s) for s in (item.get("key_similarities") or [])],
                    key_differences=[str(d) for d in (item.get("key_differences") or [])],
                    vibe=str(item.get("vibe") or ""),
                ))
            except (ValueError, TypeError) as e:
                logger.warning("neighborhood_twins: skipping malformed twin: %s", e)

        # Enrich each twin with real stock data from the DB
        enriched: list[NeighborhoodTwin] = []
        for twin in twins:
            stats = db.query(
                func.count(PropertyModel.id),
                func.min(PropertyModel.price),
                func.max(PropertyModel.price),
            ).filter(
                PropertyModel.city.ilike(f"%{twin.city}%"),
                PropertyModel.status == PropertyStatus.PUBLISHED,
            ).first()

            count = stats[0] or 0
            # When context_cities is provided, only include twins that have real stock
            if body.context_cities and count == 0:
                continue
            enriched.append(NeighborhoodTwin(
                postal_code=twin.postal_code,
                neighborhood_name=twin.neighborhood_name,
                city=twin.city,
                similarity_score=twin.similarity_score,
                avg_price_sqm=twin.avg_price_sqm,
                key_similarities=twin.key_similarities,
                key_differences=twin.key_differences,
                vibe=twin.vibe,
                available_count=count,
                price_from=int(stats[1]) if stats[1] else None,
                price_to=int(stats[2]) if stats[2] else None,
            ))
            if len(enriched) >= body.max_results:
                break

        if not enriched:
            return NeighborhoodTwinsResponse(
                source_postal_code=body.postal_code,
                twins=[],
                low_data=True,
                disclaimer=_DISCLAIMER,
            )

        return NeighborhoodTwinsResponse(
            source_postal_code=body.postal_code,
            twins=enriched,
            low_data=False,
            disclaimer=_DISCLAIMER,
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.error("neighborhood_twins: unexpected error postal_code=%s: %s", body.postal_code, exc)
        raise HTTPException(status_code=500, detail=f"Error inesperado al buscar barrios gemelos: {exc}")
