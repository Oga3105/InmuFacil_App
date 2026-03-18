"""
Price Validator — Validacion de precio de oferta con Gemini.

Endpoints:
  POST /ai/validate-price   Veredicto sobre si una oferta es justa respecto al precio pedido
"""
from __future__ import annotations

import json
import logging
import os

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter(prefix="/ai", tags=["Price Validator"])
logger = logging.getLogger(__name__)

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
async def validate_price(body: PriceValidationRequest) -> PriceValidationResponse:
    """
    Analiza si una oferta de compra es justa en relacion al precio de venta
    y al contexto del mercado de la zona usando Gemini Flash.
    """
    try:
        from google import genai
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

    pct_diff = ((body.offer_price - body.asking_price) / body.asking_price) * 100

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
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[prompt],
        )
        raw = (response.text or "").strip()

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

        return PriceValidationResponse(
            verdict=verdict,
            confidence=confidence,
            reasoning=reasoning,
            risk_level=risk_level,
        )

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
