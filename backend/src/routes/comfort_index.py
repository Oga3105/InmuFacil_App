"""
Comfort Index — Analiza factores de confort invisible para una propiedad.

Endpoints:
  GET  /properties/{property_id}/comfort-index
       Cache-aside: devuelve cache si existe y no expiró, o llama a Gemini si
       el vendedor dio consentimiento. Si no hay consentimiento, devuelve
       estado 'no_consent' para que el comprador pueda solicitarlo.

  POST /properties/{property_id}/request-comfort
       El comprador solicita al vendedor que active el análisis de confort.
       Envía email al vendedor via IONOS y devuelve confirmación.
"""
from __future__ import annotations

import json
import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session, joinedload

from backend.src.config.database import get_db
from backend.src.models import Property, User
from backend.src.models.ai_consent import AIConsentLog
from backend.src.services.gemini_service import call_with_fallback, get_client
from backend.src.services.email_service import send_comfort_request_email
from backend.src.utils.ai_rate_limit import check_ai_rate_limit
from backend.src.utils.security import get_current_active_user

router = APIRouter(tags=["Comfort Index"])
logger = logging.getLogger(__name__)

_CACHE_TTL_DAYS = 30
_DISCLAIMER = (
    "Indice estimado por IA a partir de datos publicos y caracteristicas declaradas. "
    "No sustituye una inspeccion tecnica profesional."
)


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class ComfortDimension(BaseModel):
    score: int
    label: str
    factors: list[str]


class ComfortIndexResponse(BaseModel):
    status: str  # "ok" | "no_consent" | "low_data"
    overall_score: int
    grade: str
    noise_dimension: ComfortDimension
    light_dimension: ComfortDimension
    air_dimension: ComfortDimension
    connectivity_dimension: ComfortDimension
    thermal_dimension: ComfortDimension
    low_data: bool
    disclaimer: str
    cached: bool = False


class ComfortRequestResponse(BaseModel):
    sent: bool
    message: str


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_EMPTY_DIM = ComfortDimension(score=0, label="Sin datos", factors=[])

_NO_CONSENT_RESPONSE = ComfortIndexResponse(
    status="no_consent",
    overall_score=0,
    grade="D",
    noise_dimension=_EMPTY_DIM,
    light_dimension=_EMPTY_DIM,
    air_dimension=_EMPTY_DIM,
    connectivity_dimension=_EMPTY_DIM,
    thermal_dimension=_EMPTY_DIM,
    low_data=True,
    disclaimer=_DISCLAIMER,
    cached=False,
)


def _score_to_grade(score: int) -> str:
    if score >= 90:
        return "A+"
    if score >= 80:
        return "A"
    if score >= 65:
        return "B"
    if score >= 50:
        return "C"
    return "D"


def _cache_is_valid(prop: Property) -> bool:
    if not prop.ai_comfort_data_cache or not prop.ai_comfort_cache_expires_at:
        return False
    expires = prop.ai_comfort_cache_expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    return datetime.now(timezone.utc) < expires


def _parse_cached(prop: Property) -> ComfortIndexResponse | None:
    try:
        data = json.loads(prop.ai_comfort_data_cache)
        return ComfortIndexResponse(**data, cached=True, status="ok")
    except Exception:
        return None


def _call_gemini(prop: Property) -> ComfortIndexResponse:
    """Call Gemini and return a parsed ComfortIndexResponse. Raises on failure."""
    client = get_client()

    features = prop.features
    floor_info = f"Planta: {prop.floor}" if prop.floor else "Planta: desconocida"
    orientation_info = (
        f"Orientacion: {features.orientation.value if features and features.orientation else 'desconocida'}"
    )
    year_info = (
        f"Ano de construccion: {features.construction_year}"
        if features and features.construction_year
        else "Ano: desconocido"
    )
    postal_code = prop.postal_code or ""
    address = prop.location or prop.street or ""

    prompt = f"""Eres un experto en confort habitacional y bienestar residencial en el mercado espanol.

Analiza el confort invisible para la siguiente propiedad:
- Codigo postal: {postal_code}
- Direccion: {address}
- {floor_info}
- {orientation_info}
- {year_info}

Evalua exactamente estas 5 dimensiones con puntuaciones de 0 a 100:
1. RUIDO (noise): Nivel de exposicion a contaminacion acustica (trafico, industria, ocio nocturno)
2. LUZ (light): Luz natural recibida segun orientacion, planta y entorno urbano
3. AIRE (air): Calidad del aire basado en proximidad a zonas verdes, trafico y contaminacion industrial
4. CONECTIVIDAD (connectivity): Acceso a transporte publico, infraestructuras y servicios esenciales
5. TERMICO (thermal): Confort termico estimado segun orientacion, ano de construccion y clima de la zona

REGLAS CRITICAS:
1. Score 0-100 donde 100 es perfecto y 0 es inaceptable.
2. Cada dimension incluye 2-4 factores CONCRETOS y verificables que justifican la puntuacion.
3. El label de cada dimension debe ser una frase corta que resume el estado.
4. Si no tienes datos suficientes para una dimension, asigna score=50 y low_data=true.
5. Responde EXCLUSIVAMENTE con un objeto JSON valido sin markdown ni texto extra.

Formato obligatorio:
{{
  "overall_score": <int 0-100, media ponderada>,
  "low_data": <true|false>,
  "noise": {{"score": <int>, "label": "<texto>", "factors": ["<f1>", "<f2>"]}},
  "light": {{"score": <int>, "label": "<texto>", "factors": ["<f1>", "<f2>"]}},
  "air": {{"score": <int>, "label": "<texto>", "factors": ["<f1>", "<f2>"]}},
  "connectivity": {{"score": <int>, "label": "<texto>", "factors": ["<f1>", "<f2>"]}},
  "thermal": {{"score": <int>, "label": "<texto>", "factors": ["<f1>", "<f2>"]}}
}}"""

    raw, _ = call_with_fallback(client, contents=[prompt], preferred_model="gemini-2.5-flash")

    if raw.startswith("```"):
        lines = raw.splitlines()
        raw = "\n".join(line for line in lines if not line.startswith("```")).strip()

    data = json.loads(raw)

    def _parse_dim(key: str) -> ComfortDimension:
        d = data.get(key) or {}
        score = max(0, min(100, int(d.get("score") or 50)))
        label = str(d.get("label") or "")
        factors = [str(f) for f in (d.get("factors") or [])]
        return ComfortDimension(score=score, label=label, factors=factors)

    overall_score = max(0, min(100, int(data.get("overall_score") or 50)))
    low_data = bool(data.get("low_data", False))

    return ComfortIndexResponse(
        status="ok",
        overall_score=overall_score,
        grade=_score_to_grade(overall_score),
        noise_dimension=_parse_dim("noise"),
        light_dimension=_parse_dim("light"),
        air_dimension=_parse_dim("air"),
        connectivity_dimension=_parse_dim("connectivity"),
        thermal_dimension=_parse_dim("thermal"),
        low_data=low_data,
        disclaimer=_DISCLAIMER,
        cached=False,
    )


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.get("/properties/{property_id}/comfort-index", response_model=ComfortIndexResponse)
async def get_comfort_index(
    property_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> ComfortIndexResponse:
    """
    Cache-aside comfort index for a property.

    - If seller gave GDPR consent AND cache is valid: return cached result.
    - If seller gave GDPR consent AND cache is expired/missing: call Gemini, save, return.
    - If seller has NOT given consent: return status='no_consent'.
    """
    prop = (
        db.query(Property)
        .options(joinedload(Property.features))
        .filter(Property.id == property_id)
        .first()
    )
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")

    if not prop.ai_comfort_consent:
        return _NO_CONSENT_RESPONSE

    # Rate limit only when we will actually call Gemini (cache miss)
    if not _cache_is_valid(prop):
        ip = request.client.host if request.client else "unknown"
        await check_ai_rate_limit(current_user.id, "comfort_index", db, ip)

    # Return cached result if still valid
    if _cache_is_valid(prop):
        cached = _parse_cached(prop)
        if cached:
            return cached

    # Call Gemini
    try:
        result = _call_gemini(prop)
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except (json.JSONDecodeError, ValueError) as e:
        logger.warning("comfort_index: JSON parse failed for property_id=%s: %s", property_id, e)
        # Return low_data fallback but still save nothing
        return ComfortIndexResponse(
            status="low_data",
            overall_score=0,
            grade="D",
            noise_dimension=_EMPTY_DIM,
            light_dimension=_EMPTY_DIM,
            air_dimension=_EMPTY_DIM,
            connectivity_dimension=_EMPTY_DIM,
            thermal_dimension=_EMPTY_DIM,
            low_data=True,
            disclaimer=_DISCLAIMER,
        )
    except Exception as e:
        logger.error("comfort_index: unexpected error property_id=%s: %s", property_id, e)
        raise HTTPException(status_code=500, detail=f"Error inesperado: {e}")

    # Persist cache (exclude 'cached' field from stored JSON)
    cache_payload = result.model_dump(exclude={"cached", "status"})
    prop.ai_comfort_data_cache = json.dumps(cache_payload)
    prop.ai_comfort_cache_expires_at = datetime.now(timezone.utc) + timedelta(days=_CACHE_TTL_DAYS)
    db.commit()

    return result


@router.post("/properties/{property_id}/request-comfort", response_model=ComfortRequestResponse)
async def request_comfort_from_seller(
    property_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> ComfortRequestResponse:
    """
    Buyer requests the seller to activate the AI comfort analysis.
    Sends an IONOS email to the property owner and logs the intent.
    """
    prop = db.query(Property).filter(Property.id == property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")

    seller = db.query(User).filter(User.id == prop.owner_id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Seller not found")

    if prop.ai_comfort_consent:
        return ComfortRequestResponse(
            sent=False,
            message="El vendedor ya tiene el análisis de confort activado.",
        )

    # Log buyer intent for GDPR traceability
    log_entry = AIConsentLog(
        user_id=current_user.id,
        action_type="comfort_index_request",
        action_label="Solicitud de informe de confort al vendedor",
        data_categories='["property_id", "buyer_identity"]',
        purpose="Notificar al vendedor para que active el análisis de confort IA",
        ai_provider="Google Gemini",
        consent_text_version="v1.0",
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
        property_id=str(property_id),
    )
    db.add(log_entry)
    db.commit()

    sent = await send_comfort_request_email(
        seller_email=seller.email,
        seller_name=seller.full_name,
        property_title=prop.title or f"Propiedad #{property_id}",
        buyer_name=current_user.full_name,
    )

    return ComfortRequestResponse(
        sent=sent,
        message=(
            "Hemos notificado al vendedor. Si activa el análisis, verás el informe aquí pronto."
            if sent
            else "No se pudo enviar el email al vendedor. Inténtalo más tarde."
        ),
    )


# ---------------------------------------------------------------------------
# Legacy compatibility endpoint (for Flutter web builds prior to cache-aside)
# POST /ai/comfort-index — kept so the old production build doesn't break
# ---------------------------------------------------------------------------

class _LegacyComfortRequest(BaseModel):
    postal_code: str
    address: str
    floor: int | None = None
    orientation: str | None = None
    building_year: int | None = None


@router.post("/ai/comfort-index")
async def legacy_comfort_index(
    body: _LegacyComfortRequest,
    request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Backward-compatible endpoint for Flutter web builds compiled before the
    cache-aside refactor. Calls Gemini directly without caching.
    Remove once the new Flutter build is deployed to production.
    """
    ip = request.client.host if request.client else "unknown"
    await check_ai_rate_limit(current_user.id, "comfort_index", db, ip)

    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    floor_info = f"Planta: {body.floor}" if body.floor is not None else "Planta: desconocida"
    orientation_info = f"Orientacion: {body.orientation}" if body.orientation else "Orientacion: desconocida"
    year_info = f"Ano de construccion: {body.building_year}" if body.building_year else "Ano: desconocido"

    prompt = f"""Eres un experto en confort habitacional en el mercado espanol.
Analiza el confort invisible para:
- Codigo postal: {body.postal_code}
- Direccion: {body.address}
- {floor_info} / {orientation_info} / {year_info}

Evalua 5 dimensiones (0-100): ruido, luz, aire, conectividad, termico.
Responde EXCLUSIVAMENTE con JSON valido:
{{"overall_score":<int>,"low_data":<bool>,"noise":{{"score":<int>,"label":"<txt>","factors":["<f>"]}},"light":{{"score":<int>,"label":"<txt>","factors":["<f>"]}},"air":{{"score":<int>,"label":"<txt>","factors":["<f>"]}},"connectivity":{{"score":<int>,"label":"<txt>","factors":["<f>"]}},"thermal":{{"score":<int>,"label":"<txt>","factors":["<f>"]}}}}"""

    try:
        raw, _ = call_with_fallback(client, contents=[prompt], preferred_model="gemini-2.5-flash")
        if raw.startswith("```"):
            raw = "\n".join(l for l in raw.splitlines() if not l.startswith("```")).strip()
        data = json.loads(raw)

        def _dim(key: str) -> dict:
            d = data.get(key) or {}
            return {"score": max(0, min(100, int(d.get("score") or 50))),
                    "label": str(d.get("label") or ""),
                    "factors": [str(f) for f in (d.get("factors") or [])]}

        overall = max(0, min(100, int(data.get("overall_score") or 50)))
        return {
            "overall_score": overall,
            "grade": _score_to_grade(overall),
            "noise_dimension": _dim("noise"),
            "light_dimension": _dim("light"),
            "air_dimension": _dim("air"),
            "connectivity_dimension": _dim("connectivity"),
            "thermal_dimension": _dim("thermal"),
            "low_data": bool(data.get("low_data", False)),
            "disclaimer": _DISCLAIMER,
        }
    except (json.JSONDecodeError, ValueError):
        raise HTTPException(status_code=502, detail="Error procesando respuesta de IA")
    except Exception as exc:
        logger.error("legacy_comfort_index error: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))
