"""
Invisible Comfort Index — Analiza factores de confort no visibles para una propiedad.

Endpoints:
  POST /ai/comfort-index   Devuelve puntuacion y factores de confort por dimensiones
"""
from __future__ import annotations

import json
import logging
import os

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from backend.src.services.gemini_service import call_with_fallback, get_client

router = APIRouter(prefix="/ai", tags=["Comfort Index"])
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class ComfortIndexRequest(BaseModel):
    postal_code: str
    address: str
    floor: int | None = None
    orientation: str | None = None  # "N", "S", "E", "O", "NE", etc.
    building_year: int | None = None


class ComfortDimension(BaseModel):
    score: int  # 0-100
    label: str
    factors: list[str]


class ComfortIndexResponse(BaseModel):
    overall_score: int  # 0-100
    grade: str  # "A+" | "A" | "B" | "C" | "D"
    noise_dimension: ComfortDimension
    light_dimension: ComfortDimension
    air_dimension: ComfortDimension
    connectivity_dimension: ComfortDimension
    thermal_dimension: ComfortDimension
    low_data: bool
    disclaimer: str


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_DISCLAIMER = (
    "Indice estimado por IA a partir de datos publicos y caracteristicas declaradas. "
    "No sustituye una inspeccion tecnica profesional."
)

_LOW_DATA_RESPONSE = ComfortIndexResponse(
    overall_score=0,
    grade="D",
    noise_dimension=ComfortDimension(score=0, label="Sin datos", factors=[]),
    light_dimension=ComfortDimension(score=0, label="Sin datos", factors=[]),
    air_dimension=ComfortDimension(score=0, label="Sin datos", factors=[]),
    connectivity_dimension=ComfortDimension(score=0, label="Sin datos", factors=[]),
    thermal_dimension=ComfortDimension(score=0, label="Sin datos", factors=[]),
    low_data=True,
    disclaimer=_DISCLAIMER,
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


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------


@router.post("/comfort-index", response_model=ComfortIndexResponse)
async def get_comfort_index(body: ComfortIndexRequest) -> ComfortIndexResponse:
    """
    Analiza el confort invisible de una propiedad usando Gemini.

    Evalua 5 dimensiones: ruido, luz natural, calidad del aire, conectividad,
    y confort termico. Cada dimension tiene score (0-100) y factores detectados.
    """
    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    floor_info = f"Planta: {body.floor}" if body.floor is not None else "Planta: desconocida"
    orientation_info = f"Orientacion: {body.orientation}" if body.orientation else "Orientacion: desconocida"
    year_info = f"Ano de construccion: {body.building_year}" if body.building_year else "Ano: desconocido"

    prompt = f"""Eres un experto en confort habitacional y bienestar residencial en el mercado espanol.

Analiza el confort invisible para la siguiente propiedad:
- Codigo postal: {body.postal_code}
- Direccion: {body.address}
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
3. El label de cada dimension debe ser una frase corta que resume el estado (ej: "Zona tranquila", "Ruidoso de noche").
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

    try:
        raw, _ = call_with_fallback(client, contents=[prompt], preferred_model="gemini-2.5-flash")

        if raw.startswith("```"):
            lines = raw.splitlines()
            raw = "\n".join(
                line for line in lines if not line.startswith("```")
            ).strip()

        try:
            data = json.loads(raw)
        except (json.JSONDecodeError, ValueError):
            logger.warning(
                "comfort_index: JSON parse failed for postal_code=%s",
                body.postal_code,
            )
            return _LOW_DATA_RESPONSE

        if bool(data.get("low_data", False)):
            return _LOW_DATA_RESPONSE

        def _parse_dim(key: str) -> ComfortDimension:
            d = data.get(key) or {}
            score = max(0, min(100, int(d.get("score") or 50)))
            label = str(d.get("label") or "")
            factors = [str(f) for f in (d.get("factors") or [])]
            return ComfortDimension(score=score, label=label, factors=factors)

        overall_score = max(0, min(100, int(data.get("overall_score") or 50)))

        return ComfortIndexResponse(
            overall_score=overall_score,
            grade=_score_to_grade(overall_score),
            noise_dimension=_parse_dim("noise"),
            light_dimension=_parse_dim("light"),
            air_dimension=_parse_dim("air"),
            connectivity_dimension=_parse_dim("connectivity"),
            thermal_dimension=_parse_dim("thermal"),
            low_data=False,
            disclaimer=_DISCLAIMER,
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "comfort_index: unexpected error postal_code=%s: %s",
            body.postal_code,
            exc,
        )
        raise HTTPException(
            status_code=500,
            detail=f"Error inesperado al calcular el indice de confort: {exc}",
        )
