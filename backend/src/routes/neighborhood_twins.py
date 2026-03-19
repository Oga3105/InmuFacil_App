"""
Neighborhood Twins -- Encuentra zonas similares a un codigo postal dado.

Endpoints:
  POST /ai/neighborhood-twins  Devuelve lista de barrios gemelos con puntuacion de similitud
"""
from __future__ import annotations

import json
import logging
import os

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/ai", tags=["Neighborhood Twins"])
logger = logging.getLogger(__name__)


class NeighborhoodTwinsRequest(BaseModel):
    postal_code: str
    city: str | None = None
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
async def get_neighborhood_twins(body: NeighborhoodTwinsRequest) -> NeighborhoodTwinsResponse:
    """
    Encuentra barrios gemelos al codigo postal dado, filtrados por perfil de lifestyle.
    """
    try:
        from google import genai
    except ImportError:
        raise HTTPException(status_code=503, detail="Servicio de IA no disponible.")

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=503, detail="Servicio de IA no configurado.")

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

    prompt = f"""Eres un experto en urbanismo espanol. Encuentra los {body.max_results} barrios mas similares al codigo postal {body.postal_code}{city_context}.
Perfil de usuario:{lifestyle_context if lifestyle_context else " generico"}

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
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(model="gemini-2.5-flash", contents=[prompt])
        raw = (response.text or "").strip()

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

        twins: list[NeighborhoodTwin] = []
        for item in (data.get("twins") or []):
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

        return NeighborhoodTwinsResponse(
            source_postal_code=body.postal_code,
            twins=twins[: body.max_results],
            low_data=False,
            disclaimer=_DISCLAIMER,
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.error("neighborhood_twins: unexpected error postal_code=%s: %s", body.postal_code, exc)
        raise HTTPException(status_code=500, detail=f"Error inesperado al buscar barrios gemelos: {exc}")
