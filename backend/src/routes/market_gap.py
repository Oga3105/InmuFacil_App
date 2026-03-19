"""
Market Gap Analyzer — Negotiation gap between asking price and real transaction price.

Endpoints:
  POST /ai/market-gap   Returns real closing price per m2 and negotiation gap analysis
                        for a given postal code and property.
"""
from __future__ import annotations

import json
import logging
import os

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter(prefix="/ai", tags=["Market Gap Analyzer"])
logger = logging.getLogger(__name__)

_DATA_SOURCE = "Fuente: Ministerio de Vivienda / Catastro (datos estimados por IA)"
_DISCLAIMER = "Cifras estimadas por IA. Verifique con datos oficiales del Ministerio de Vivienda."
_LOW_DATA_MESSAGE = (
    "Datos de cierre insuficientes para calcular el Gap de negociacion en esta calle"
)


class MarketGapRequest(BaseModel):
    postal_code: str = Field(..., min_length=1)
    asking_price: int = Field(..., gt=0)
    surface_m2: float = Field(..., gt=0)
    user_offer: int = Field(..., gt=0)


class MarketGapResponse(BaseModel):
    real_transaction_price_per_m2: int | None
    gap_pct: float | None
    offer_analysis: str
    recommendation: str
    sample_size: int
    low_data: bool
    data_source: str
    disclaimer: str


def _compute_gap_pct(asking_price: int, real_transaction_price: int) -> float:
    """gap_pct = (asking_price - real_transaction_price) / asking_price * 100"""
    if asking_price <= 0:
        return 0.0
    return (asking_price - real_transaction_price) / asking_price * 100.0


def _compute_offer_analysis(
    asking_price: int,
    user_offer: int,
    gap_pct: float,
) -> str:
    """
    Returns offer analysis string based on user offer vs market gap.

    The user's implied rebaja percentage = (asking - user_offer) / asking * 100.
    If user rebaja < gap_pct: underutilized margin.
    If user rebaja > gap_pct: aggressive offer with rejection risk.
    """
    if asking_price <= 0:
        return "No se puede calcular el analisis de la oferta."

    user_rebaja_pct = (asking_price - user_offer) / asking_price * 100.0

    if user_rebaja_pct < gap_pct:
        return "Margen de negociacion infrautilizado"
    return "Oferta agresiva con riesgo de rechazo"


@router.post("/market-gap", response_model=MarketGapResponse)
async def get_market_gap(body: MarketGapRequest) -> MarketGapResponse:
    """
    Estimates the real transaction closing price per m2 for a postal code using
    Gemini Flash, then calculates the negotiation gap against the asking price.

    Truth clause: if sample_size < 10, returns low_data=True with null gap values
    rather than extrapolating unreliable data.
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

    prompt = f"""Eres un analista de datos inmobiliarios especializado en el mercado espanol.

Tu tarea es estimar el precio REAL de cierre (precio al que se firman las escrituras,
no el precio de oferta publicado) por metro cuadrado en el codigo postal "{body.postal_code}",
basandote en datos de transacciones reales del Ministerio de Vivienda, Catastro y
registros notariales espanoles.

Contexto de la propiedad a analizar:
  - Codigo postal: {body.postal_code}
  - Precio solicitado por el vendedor: {body.asking_price} EUR
  - Superficie: {body.surface_m2} m2
  - Precio por m2 solicitado: {int(body.asking_price / body.surface_m2)} EUR/m2

REGLAS CRITICAS:
1. Si no tienes datos de transacciones reales de cierre para esa zona (menos de 10
   transacciones recientes conocidas), devuelve sample_size=0 y price_per_m2=0.
   NUNCA extrapoles ni inventes precios de cierre sin datos reales.
2. Si conoces datos reales de cierre para esa zona, proporciona la estimacion.
3. El precio de cierre suele ser inferior al precio de oferta publicado.
4. Proporciona una recomendacion breve de negociacion para el comprador (max 60 palabras).
5. Responder EXCLUSIVAMENTE con un objeto JSON valido sin markdown ni texto extra.

Formato de respuesta obligatorio:
{{
  "real_transaction_price_per_m2": <entero EUR/m2 de cierre real, o 0 si sin datos>,
  "sample_size": <numero de transacciones conocidas, 0 si sin datos>,
  "recommendation": "<recomendacion breve de negociacion para el comprador, en espanol>"
}}"""

    try:
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[prompt],
        )
        raw = (response.text or "").strip()

        if raw.startswith("```"):
            lines = raw.splitlines()
            raw = "\n".join(
                line for line in lines if not line.startswith("```")
            ).strip()

        try:
            data = json.loads(raw)
        except (json.JSONDecodeError, ValueError):
            logger.warning(
                "market_gap: JSON parse failed for postal_code=%s", body.postal_code
            )
            data = {}

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "market_gap: unexpected error postal_code=%s: %s", body.postal_code, exc
        )
        raise HTTPException(
            status_code=503,
            detail="Error al calcular el gap de mercado. Intentalo de nuevo.",
        )

    real_price_per_m2: int = 0
    try:
        real_price_per_m2 = int(data.get("real_transaction_price_per_m2") or 0)
    except (ValueError, TypeError):
        real_price_per_m2 = 0

    sample_size: int = 0
    try:
        sample_size = int(data.get("sample_size") or 0)
    except (ValueError, TypeError):
        sample_size = 0

    recommendation: str = str(
        data.get("recommendation") or "Negocie basandose en datos de mercado actualizados."
    )

    # Truth clause: insufficient closing data
    if sample_size < 10 or real_price_per_m2 <= 0:
        return MarketGapResponse(
            real_transaction_price_per_m2=None,
            gap_pct=None,
            offer_analysis=_LOW_DATA_MESSAGE,
            recommendation=recommendation,
            sample_size=sample_size,
            low_data=True,
            data_source=_DATA_SOURCE,
            disclaimer=_DISCLAIMER,
        )

    real_total_price = int(real_price_per_m2 * body.surface_m2)
    gap_pct = _compute_gap_pct(body.asking_price, real_total_price)
    offer_analysis = _compute_offer_analysis(body.asking_price, body.user_offer, gap_pct)

    return MarketGapResponse(
        real_transaction_price_per_m2=real_price_per_m2,
        gap_pct=round(gap_pct, 1),
        offer_analysis=offer_analysis,
        recommendation=recommendation,
        sample_size=sample_size,
        low_data=False,
        data_source=_DATA_SOURCE,
        disclaimer=_DISCLAIMER,
    )
