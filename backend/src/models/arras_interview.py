"""
ArrasInterview model — Entrevista dinamica para el Contrato de Arras Penitenciales.
Almacena las respuestas de comprador y vendedor a la entrevista guiada.
Cuando ambas partes confirman, se genera el borrador PDF.
"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.types import JSON
from sqlalchemy.sql import func
from .base import Base


class ArrasInterview(Base):
    """
    One record per offer. UPSERT semantics.
    Tracks the negotiated parameters for the Arras Penitenciales contract.
    """
    __tablename__ = "arras_interviews"

    id = Column(Integer, primary_key=True, index=True)
    offer_id = Column(
        Integer,
        ForeignKey("offers.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    # --- Pactado en la entrevista ---
    # Cantidad de arras (porcentaje o importe fijo sobre el precio de la oferta)
    deposit_percentage = Column(Integer, nullable=True)    # e.g. 10 (for 10%)
    deposit_amount = Column(Integer, nullable=True)        # calculado: offer.amount * deposit_percentage / 100

    # Plazo limite para firmar escrituras (dias desde firma de arras)
    deadline_days = Column(Integer, nullable=True)         # e.g. 60

    # Penalizacion para el comprador: pierde las arras si se echa atras
    buyer_penalty_text = Column(Text, nullable=True)

    # Penalizacion para el vendedor: devuelve el doble de las arras si se echa atras
    seller_penalty_text = Column(Text, nullable=True)

    # Condiciones adicionales pactadas
    additional_conditions = Column(Text, nullable=True)

    # Metodo de financiacion aceptado (hereda de solvency pero confirmado aqui)
    payment_method = Column(String(50), nullable=True)

    # Datos notariales provisionales
    notary_city = Column(String(200), nullable=True)

    # --- Estado de confirmacion dual ---
    buyer_confirmed = Column(Boolean, default=False, nullable=False)
    buyer_confirmed_at = Column(DateTime(timezone=True), nullable=True)
    seller_confirmed = Column(Boolean, default=False, nullable=False)
    seller_confirmed_at = Column(DateTime(timezone=True), nullable=True)

    # PDF generado (ruta local tras confirmacion mutua)
    draft_pdf_path = Column(String, nullable=True)

    # Metadata adicional (respuestas libres en JSON)
    extra_answers_json = Column(JSON, nullable=True)

    # --- V2: Entrevistas separadas por rol (Sprint V23) ---
    # JSON con todas las respuestas del comprador / vendedor
    buyer_answers_json = Column(JSON, nullable=True)
    seller_answers_json = Column(JSON, nullable=True)

    # Confirmacion individual de la entrevista (independiente de buyer_confirmed legacy)
    buyer_interview_confirmed = Column(Boolean, default=False, nullable=False, server_default="false")
    seller_interview_confirmed = Column(Boolean, default=False, nullable=False, server_default="false")

    # Contrato generado por IA
    contract_text = Column(Text, nullable=True)
    # null | "generating" | "ready" | "buyer_accepted" | "seller_accepted" | "fully_accepted"
    contract_status = Column(String(30), nullable=True)
    generation_count = Column(Integer, default=0, nullable=False, server_default="0")

    # Aceptacion del contrato por cada parte
    buyer_contract_accepted = Column(Boolean, default=False, nullable=False, server_default="false")
    buyer_contract_accepted_at = Column(DateTime(timezone=True), nullable=True)
    seller_contract_accepted = Column(Boolean, default=False, nullable=False, server_default="false")
    seller_contract_accepted_at = Column(DateTime(timezone=True), nullable=True)

    # Notas de rechazo (para solicitar cambios)
    buyer_rejection_notes = Column(Text, nullable=True)
    seller_rejection_notes = Column(Text, nullable=True)

    # IBAN del vendedor cifrado (PII)
    seller_iban_enc = Column(String, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    offer = relationship("PropertyOffer", backref="arras_interview", foreign_keys=[offer_id])
