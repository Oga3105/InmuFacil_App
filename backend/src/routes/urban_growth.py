"""
Urban Growth Index — Proyeccion de revalorizacion a 5 anos por codigo postal.

Endpoints:
  POST /ai/urban-growth   Devuelve tasa de crecimiento estimada y senales urbanas
"""
from __future__ import annotations

import json
import logging
import math
import os

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from backend.src.services.gemini_service import call_with_fallback, get_client

router = APIRouter(prefix="/ai", tags=["Urban Growth Index"])
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class UrbanGrowthRequest(BaseModel):
    postal_code: str
    address: str


class UrbanGrowthResponse(BaseModel):
    base_growth_rate: float
    neighborhood_bonus: float
    projected_value_5yr_pct: float | None
    growth_signals: list[str]
    urban_milestones: list[str]
    zone_type: str  # "mature" | "emerging" | "declining" | "unknown"
    low_data: bool
    message: str | None
    disclaimer: str


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_DISCLAIMER = (
    "Proyeccion estimada por IA. No constituye garantia de revalorizacion. "
    "Sujeto a factores de mercado externos."
)

_LOW_DATA_MESSAGE = (
    "Datos de proyeccion limitados por falta de actividad urbanistica reciente"
)

_MATURE_MESSAGE = "Zona Madura: Crecimiento estable alineado con el IPC"

_LOW_DATA_RESPONSE = UrbanGrowthResponse(
    base_growth_rate=0.0,
    neighborhood_bonus=0.0,
    projected_value_5yr_pct=None,
    growth_signals=[],
    urban_milestones=[],
    zone_type="unknown",
    low_data=True,
    message=_LOW_DATA_MESSAGE,
    disclaimer=_DISCLAIMER,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _compound_projection(base_rate: float, bonus: float, years: int = 5) -> float:
    """
    Calcula la revalorizacion compuesta a N anos como porcentaje.
    Formula: ((1 + base + bonus)^years - 1) * 100
    """
    return (math.pow(1 + base_rate + bonus, years) - 1) * 100


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------


@router.post("/urban-growth", response_model=UrbanGrowthResponse)
async def get_urban_growth(body: UrbanGrowthRequest) -> UrbanGrowthResponse:
    """
    Estima el potencial de revalorizacion a 5 anos para una zona usando Gemini.

    Reglas criticas:
    - No predice subidas de precio sin citar un factor detonante concreto.
    - Si no hay actividad urbanistica reciente, devuelve low_data=True.
    - Para zonas maduras: proyeccion = base_growth_rate * 5 (alineado con IPC).
    - Para zonas emergentes: usa formula compuesta con neighborhood_bonus.
    """
    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    prompt = f"""Eres un analista urbano especializado en el mercado inmobiliario espanol.

Tu tarea es evaluar el potencial de crecimiento urbano para la siguiente ubicacion:
- Codigo postal: {body.postal_code}
- Direccion: {body.address}

REGLAS CRITICAS OBLIGATORIAS:
1. NO predices subidas de precio sin citar UN factor detonante concreto y verificable
   (nueva infraestructura, plan urbanistico aprobado, empresa ancla instalada, etc.).
2. Si no tienes datos de actividad urbanistica reciente para esa zona, devuelve
   low_data=true con listas vacias.
3. growth_signals debe contener solo negocios ancla o proyectos REALES y VERIFICABLES.
4. urban_milestones debe contener solo hitos REALES con fecha conocida o estimada.
5. zone_type debe ser uno de: "mature", "emerging", "declining", "unknown".
   - "mature": zona consolidada, crecimiento estable alineado con IPC
   - "emerging": zona con factores detonantes activos
   - "declining": zona con tendencia negativa documentada
   - "unknown": sin datos suficientes
6. base_growth_rate y neighborhood_bonus son decimales (ej: 0.03 = 3%).
   Valores realistas para Espana: entre -0.02 y 0.06 anuales.
7. Responde EXCLUSIVAMENTE con un objeto JSON valido sin markdown ni texto extra.

Formato de respuesta obligatorio:
{{
  "base_growth_rate": <float anual, ej: 0.025>,
  "neighborhood_bonus": <float adicional por factores locales, ej: 0.015>,
  "growth_signals": ["<negocio o proyecto 1>", "<negocio o proyecto 2>"],
  "urban_milestones": ["<hito con fecha>", "<hito con fecha>"],
  "zone_type": "<mature|emerging|declining|unknown>",
  "low_data": <true|false>
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
                "urban_growth: JSON parse failed for postal_code=%s",
                body.postal_code,
            )
            return _LOW_DATA_RESPONSE

        low_data = bool(data.get("low_data", True))
        if low_data:
            return _LOW_DATA_RESPONSE

        zone_type = str(data.get("zone_type") or "unknown").lower()
        if zone_type not in ("mature", "emerging", "declining", "unknown"):
            zone_type = "unknown"

        base_growth_rate = float(data.get("base_growth_rate") or 0.0)
        neighborhood_bonus = float(data.get("neighborhood_bonus") or 0.0)

        # Clamp to realistic range
        base_growth_rate = max(-0.05, min(0.10, base_growth_rate))
        neighborhood_bonus = max(-0.05, min(0.10, neighborhood_bonus))

        growth_signals: list[str] = [
            str(s) for s in (data.get("growth_signals") or [])
        ]
        urban_milestones: list[str] = [
            str(m) for m in (data.get("urban_milestones") or [])
        ]

        # Projection formula
        if zone_type == "mature":
            # Aligned with IPC: linear approximation
            projected_value_5yr_pct: float | None = base_growth_rate * 5 * 100
            message: str | None = _MATURE_MESSAGE
        elif zone_type in ("emerging", "declining"):
            projected_value_5yr_pct = _compound_projection(
                base_growth_rate, neighborhood_bonus, years=5
            )
            message = None
        else:
            projected_value_5yr_pct = None
            message = _LOW_DATA_MESSAGE

        return UrbanGrowthResponse(
            base_growth_rate=base_growth_rate,
            neighborhood_bonus=neighborhood_bonus,
            projected_value_5yr_pct=projected_value_5yr_pct,
            growth_signals=growth_signals,
            urban_milestones=urban_milestones,
            zone_type=zone_type,
            low_data=False,
            message=message,
            disclaimer=_DISCLAIMER,
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "urban_growth: unexpected error postal_code=%s: %s",
            body.postal_code,
            exc,
        )
        raise HTTPException(
            status_code=500,
            detail=f"Error inesperado al calcular el indice de crecimiento urbano: {exc}",
        )
