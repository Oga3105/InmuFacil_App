"""
Legal Guides Route — Generacion de guias legales por CCAA con Gemini Flash.

Endpoints:
  POST /ai/legal-guide   Genera guia legal orientativa para CCAA y tipo de guia
"""
from __future__ import annotations

import logging
import os
from typing import Dict

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from backend.src.services.gemini_service import call_with_fallback, get_client

router = APIRouter(prefix="/ai", tags=["Legal Guides"])
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# In-memory cache: key = "{ccaa}_{guide_type}" -> LegalGuideResponse
# ---------------------------------------------------------------------------
_guide_cache: Dict[str, "LegalGuideResponse"] = {}

VALID_GUIDE_TYPES = {
    "itp_guide",
    "arras_guide",
    "cedula_guide",
    "process_guide",
    "costs_guide",
}

DISCLAIMER = (
    "Informacion orientativa. Consulte con un profesional para su caso especifico."
)

# ---------------------------------------------------------------------------
# Prompts per guide type
# ---------------------------------------------------------------------------
_GUIDE_PROMPTS: Dict[str, str] = {
    "itp_guide": (
        "Explica el Impuesto de Transmisiones Patrimoniales (ITP) aplicable en la "
        "comunidad autonoma de {ccaa} para la compra de una vivienda de segunda mano. "
        "Incluye: tipo impositivo vigente, posibles reducciones (familia numerosa, "
        "jovenes, discapacidad), plazo de liquidacion y donde se paga. "
        "Maximo 400 palabras. Solo texto en prosa, sin listas con guiones ni titulos."
    ),
    "arras_guide": (
        "Explica el contrato de arras penitenciales en el contexto de la compraventa "
        "inmobiliaria en {ccaa}, Espana. Incluye: diferencia entre arras confirmatorias, "
        "penitenciales y penales; importe habitual (porcentaje del precio); consecuencias "
        "del incumplimiento para comprador y vendedor; y el proceso notarial en {ccaa}. "
        "Maximo 400 palabras. Solo texto en prosa, sin listas con guiones ni titulos."
    ),
    "cedula_guide": (
        "Explica la cedula de habitabilidad en {ccaa}, Espana. Incluye: que es, "
        "cuando es obligatoria para la venta, como obtenerla, coste aproximado, "
        "plazo de validez y si {ccaa} tiene normativa especifica al respecto. "
        "Maximo 400 palabras. Solo texto en prosa, sin listas con guiones ni titulos."
    ),
    "process_guide": (
        "Describe el proceso completo de compraventa de una vivienda en {ccaa}, Espana, "
        "desde la oferta inicial hasta la firma en notaria. Incluye: fases principales, "
        "documentos necesarios, plazos tipicos, intervencion de notario y registro de la "
        "propiedad, y particularidades especificas de {ccaa} si las hay. "
        "Maximo 400 palabras. Solo texto en prosa, sin listas con guiones ni titulos."
    ),
    "costs_guide": (
        "Detalla todos los costes asociados a la compra de una vivienda en {ccaa}, Espana, "
        "ademas del precio de compra. Incluye: ITP o IVA segun sea segunda mano o nueva, "
        "AJD (Actos Juridicos Documentados), honorarios notariales, registro de la propiedad, "
        "gastos de hipoteca si aplica, y otros costes tipicos en {ccaa}. "
        "Proporciona porcentajes o rangos aproximados sobre el precio de compra. "
        "Maximo 400 palabras. Solo texto en prosa, sin listas con guiones ni titulos."
    ),
}

_GUIDE_TITLES: Dict[str, str] = {
    "itp_guide": "Impuesto de Transmisiones Patrimoniales",
    "arras_guide": "Contrato de Arras Penitenciales",
    "cedula_guide": "Cedula de Habitabilidad",
    "process_guide": "Proceso de Compraventa",
    "costs_guide": "Costes de la Compra",
}


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------

class LegalGuideRequest(BaseModel):
    ccaa: str
    guide_type: str


class LegalGuideResponse(BaseModel):
    title: str
    content: str
    ccaa: str
    guide_type: str
    disclaimer: str


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------

@router.post("/legal-guide", response_model=LegalGuideResponse)
async def generate_legal_guide(request: LegalGuideRequest) -> LegalGuideResponse:
    """
    Genera una guia legal orientativa para la CCAA y tipo de guia solicitados.
    Resultados cacheados en memoria para evitar llamadas repetidas a la IA.
    """
    ccaa = request.ccaa.strip()
    guide_type = request.guide_type.strip()

    if not ccaa:
        raise HTTPException(status_code=422, detail="El campo ccaa no puede estar vacio.")

    if guide_type not in VALID_GUIDE_TYPES:
        raise HTTPException(
            status_code=422,
            detail=f"guide_type invalido. Valores permitidos: {', '.join(sorted(VALID_GUIDE_TYPES))}",
        )

    cache_key = f"{ccaa}_{guide_type}"

    if cache_key in _guide_cache:
        logger.info("[LegalGuides] Cache HIT for key: %s", cache_key)
        return _guide_cache[cache_key]

    logger.info("[LegalGuides] Cache MISS for key: %s — calling Gemini", cache_key)

    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    prompt_template = _GUIDE_PROMPTS[guide_type]
    prompt = (
        "Eres un asesor legal inmobiliario especializado en derecho espanol. "
        "Redacta en espanol peninsular, tono profesional y claro, sin emojis. "
        + prompt_template.format(ccaa=ccaa)
    )

    try:
        content, _ = call_with_fallback(
            client, contents=prompt, preferred_model="gemini-2.5-flash"
        )
        if not content:
            raise HTTPException(
                status_code=503,
                detail="La IA no pudo generar la guia. Intentalo de nuevo.",
            )
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("[LegalGuides] Gemini error for key %s: %s", cache_key, exc)
        raise HTTPException(
            status_code=503,
            detail="Error al generar la guia con IA. Intentalo de nuevo.",
        )

    result = LegalGuideResponse(
        title=_GUIDE_TITLES[guide_type],
        content=content,
        ccaa=ccaa,
        guide_type=guide_type,
        disclaimer=DISCLAIMER,
    )

    _guide_cache[cache_key] = result
    logger.info("[LegalGuides] Cached guide for key: %s", cache_key)

    return result
