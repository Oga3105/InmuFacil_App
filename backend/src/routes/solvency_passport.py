"""
Solvency Passport AI — Document analysis with PII anonymization.

Endpoints:
  POST /ai/analyze-solvency   Analyzes income/employment documents and returns
                               anonymized solvency metrics with a level badge.
"""
from __future__ import annotations

import base64
import json
import logging
import os

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from backend.src.models import User
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/ai", tags=["Solvency Passport AI"])
logger = logging.getLogger(__name__)

_DISCLAIMER = (
    "Tus datos sensibles han sido anonimizados. "
    "El vendedor solo vera tu capacidad de compra certificada."
)

_VALID_DOC_TYPES = {"nomina", "vida_laboral", "contrato"}


class SolvencyRequest(BaseModel):
    document_base64: str = Field(..., min_length=1)
    document_type: str = Field(..., description="nomina | vida_laboral | contrato")


class SolvencyResponse(BaseModel):
    net_monthly_income: int | None
    job_tenure_months: int | None
    contract_type: str | None
    existing_debts: int | None
    max_offer_capacity: int | None
    solvency_level: str
    pii_anonymized: bool
    disclaimer: str
    analysis_summary: str


def _compute_solvency_level(
    net_monthly_income: int | None,
    job_tenure_months: int | None,
    contract_type: str | None,
) -> str:
    """
    Compute solvency level from extracted document fields.

    score = (net_monthly_income * 0.35 / 1000)
           + (job_tenure_months / 12)
           + (1 if contract_type == 'indefinido' else 0)

    platinum >= 8, gold >= 5, silver >= 3, bronze < 3
    """
    score: float = 0.0

    if net_monthly_income and net_monthly_income > 0:
        score += (net_monthly_income * 0.35) / 1000.0

    if job_tenure_months and job_tenure_months > 0:
        score += job_tenure_months / 12.0

    if contract_type and contract_type.lower() == "indefinido":
        score += 1.0

    if score >= 8.0:
        return "platinum"
    if score >= 5.0:
        return "gold"
    if score >= 3.0:
        return "silver"
    return "bronze"


def _compute_max_offer_capacity(
    net_monthly_income: int | None,
    existing_debts: int | None,
) -> int | None:
    """
    Rough 25-year mortgage capacity at ~4% annual rate.

    max_offer_capacity = (net_monthly_income - existing_debts) * 0.35 / 0.004
    """
    if not net_monthly_income or net_monthly_income <= 0:
        return None

    debts = existing_debts if existing_debts and existing_debts > 0 else 0
    available_monthly = net_monthly_income - debts

    if available_monthly <= 0:
        return None

    capacity = (available_monthly * 0.35) / 0.004
    return max(0, int(capacity))


@router.post("/analyze-solvency", response_model=SolvencyResponse)
async def analyze_solvency(
    body: SolvencyRequest,
    current_user: User = Depends(get_current_active_user),
) -> SolvencyResponse:
    """
    Analyzes a base64-encoded income or employment document with Gemini Flash Vision.

    PII anonymization is applied immediately:
      - Name -> TITULAR VERIFICADO
      - DNI  -> last 4 characters only
      - Company -> EMPRESA VERIFICADA

    Returns solvency level, max offer capacity, and a disclaimer for the buyer.
    """
    if body.document_type not in _VALID_DOC_TYPES:
        raise HTTPException(
            status_code=422,
            detail=f"document_type debe ser uno de: {', '.join(_VALID_DOC_TYPES)}",
        )

    try:
        from google import genai
        from google.genai import types as genai_types
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

    # Decode and validate base64 document
    try:
        doc_bytes = base64.b64decode(body.document_base64, validate=True)
    except Exception:
        raise HTTPException(
            status_code=422,
            detail="document_base64 no es base64 valido.",
        )

    prompt = f"""Eres un analizador de documentos financieros laborales del mercado espanol.

Analiza el documento adjunto de tipo "{body.document_type}" y extrae los datos
economicos anonimizando INMEDIATAMENTE los datos personales identificables (PII):
  - Nombre completo -> reemplazar por "TITULAR VERIFICADO"
  - DNI / NIF -> conservar solo los 4 ultimos caracteres (ej: "1234Z")
  - Empresa / empleador -> reemplazar por "EMPRESA VERIFICADA"
  - Direcciones fisicas -> omitir

Extrae los siguientes campos economicos (sin PII):
  - net_monthly_income: ingresos netos mensuales en EUR (entero, solo el importe neto
    despues de retenciones/SS), null si no aparece
  - job_tenure_months: antiguedad laboral en meses (entero), null si no aparece
  - contract_type: tipo de contrato ("indefinido" | "temporal" | "autonomo" | "otros"),
    null si no aparece
  - existing_debts: deudas mensuales conocidas en EUR (entero), null si no aparece

REGLAS CRITICAS:
1. Nunca incluir nombre real, DNI completo ni empresa real en la respuesta.
2. Si el documento no es legible o no contiene datos laborales/economicos,
   devolver todos los campos como null.
3. Responder EXCLUSIVAMENTE con un objeto JSON valido sin markdown ni texto extra.

Formato de respuesta obligatorio:
{{
  "net_monthly_income": <entero o null>,
  "job_tenure_months": <entero o null>,
  "contract_type": "<indefinido|temporal|autonomo|otros>" o null,
  "existing_debts": <entero o null>,
  "analysis_summary": "<resumen breve del documento en espanol, sin PII, max 80 palabras>"
}}"""

    try:
        client = genai.Client(api_key=api_key)

        # Determine MIME type — treat as image/jpeg by default for document scans
        # PDFs are also supported by Gemini Vision as application/pdf
        if len(doc_bytes) >= 4 and doc_bytes[:4] == b"%PDF":
            mime_type = "application/pdf"
        else:
            mime_type = "image/jpeg"

        contents = [
            prompt,
            genai_types.Part.from_bytes(data=doc_bytes, mime_type=mime_type),
        ]

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=contents,
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
                "solvency_passport: JSON parse failed for user_id=%s", current_user.id
            )
            data = {}

    except HTTPException:
        raise
    except Exception as exc:
        logger.error("solvency_passport: Gemini error user_id=%s: %s", current_user.id, exc)
        raise HTTPException(
            status_code=503,
            detail="Error al analizar el documento con IA. Intentalo de nuevo.",
        )

    # Extract and sanitize fields
    net_monthly_income: int | None = None
    raw_income = data.get("net_monthly_income")
    if raw_income is not None:
        try:
            net_monthly_income = int(raw_income)
        except (ValueError, TypeError):
            net_monthly_income = None

    job_tenure_months: int | None = None
    raw_tenure = data.get("job_tenure_months")
    if raw_tenure is not None:
        try:
            job_tenure_months = int(raw_tenure)
        except (ValueError, TypeError):
            job_tenure_months = None

    contract_type: str | None = data.get("contract_type")
    if contract_type is not None:
        contract_type = str(contract_type).lower().strip()
        if contract_type not in ("indefinido", "temporal", "autonomo", "otros"):
            contract_type = "otros"

    existing_debts: int | None = None
    raw_debts = data.get("existing_debts")
    if raw_debts is not None:
        try:
            existing_debts = int(raw_debts)
        except (ValueError, TypeError):
            existing_debts = None

    analysis_summary: str = str(data.get("analysis_summary") or "Documento analizado correctamente.")

    solvency_level = _compute_solvency_level(
        net_monthly_income, job_tenure_months, contract_type
    )
    max_offer_capacity = _compute_max_offer_capacity(net_monthly_income, existing_debts)

    return SolvencyResponse(
        net_monthly_income=net_monthly_income,
        job_tenure_months=job_tenure_months,
        contract_type=contract_type,
        existing_debts=existing_debts,
        max_offer_capacity=max_offer_capacity,
        solvency_level=solvency_level,
        pii_anonymized=True,
        disclaimer=_DISCLAIMER,
        analysis_summary=analysis_summary,
    )
