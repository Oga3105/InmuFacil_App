import magic
from fastapi import HTTPException, UploadFile
import json

class ContractAnalyzer:
    """
    Hito 12.6: AI Analysis of Contracts.
    Uses Gemini (Mocked) to detect risks.
    """
    
    DISCLAIMER_TEXT = "InmuFácil AI Analysis is for informational purposes only. It does not constitute legal advice."
    DISCLAIMER_VERSION = "v1.0"
    
    @staticmethod
    async def validate_file(file: UploadFile):
        """
        Security: Validate MIME type using magic bytes.
        """
        # Read first 2KB for magic check
        header = await file.read(2048)
        await file.seek(0)
        
        mime = magic.from_buffer(header, mime=True)
        allowed_mimes = [
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "text/plain"
        ]
        
        if mime not in allowed_mimes:
            raise HTTPException(status_code=400, detail=f"Invalid file type: {mime}. Only PDF, DOCX, TXT allowed.")
        
        return True

    @staticmethod
    def estimate_cost(text: str) -> float:
        """
        Estimate cost based on tokens.
        Gemini Flash: ~$0.00045 / 1k chars? No, / 1M tokens.
        Let's assume 1 token ~ 4 chars.
        """
        tokens = len(text) / 4
        # Price: $0.10 per 1M tokens (Approx for Flash input)
        cost_usd = (tokens / 1_000_000) * 0.10
        # Min cost just to show something
        return max(cost_usd, 0.0001)

    @staticmethod
    async def analyze_text(text: str, role: str) -> dict:
        """
        Mock AI Analysis.
        In production, this calls Gemini API with a prompt tailored to 'role'.
        """
        # Simulated Latency? No need.
        
        # Mock Response based on Role
        if role.upper() == "BUYER":
            return {
                "risk_score": 35,
                "summary": "El contrato parece estándar pero falta protección sobre vicios ocultos.",
                "red_flags": [
                    "Cláusula de renuncia a saneamiento por vicios ocultos detectada.",
                    "Penalización por retraso excesiva (> 20%)."
                ],
                "green_lights": [
                    "Identificación clara de la finca.",
                    "Precio y forma de pago detallados."
                ],
                "missing_clauses": [
                    "Certificado de deuda cero con la comunidad.",
                    "Garantía de devolución de arras penitenciales."
                ],
                "cost_estimate": ContractAnalyzer.estimate_cost(text),
                "disclaimer": ContractAnalyzer.DISCLAIMER_TEXT
            }
        else: # SELLER
            return {
                "risk_score": 20,
                "summary": "Contrato favorable al vendedor, pero revisa los plazos de entrega.",
                "red_flags": [
                    "Obligación de entrega de llaves antes del pago total?"
                ],
                "green_lights": [
                    "Arras penitenciales correctamente estipuladas.",
                    "Renuncia explícita del comprador al art 1455 CC (Gastos)."
                ],
                "missing_clauses": [
                    "Cláusula anti-blanqueo de capitales (recomendada)."
                ],
                "cost_estimate": ContractAnalyzer.estimate_cost(text),
                "disclaimer": ContractAnalyzer.DISCLAIMER_TEXT
            }
