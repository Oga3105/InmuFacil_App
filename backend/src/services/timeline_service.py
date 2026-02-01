from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import List, Optional
from backend.src.models.timeline import TransactionStep, StepStatus, StepRole
from backend.src.models.offers import PropertyOffer, OfferStatus
import logging

logger = logging.getLogger("inmufacil.timeline")

# Define Standard Steps configuration
STANDARD_TIMELINE_STEPS = [
    {
        "key": "CONTRACT_GENERATION",
        "label": "Generación de Contrato",
        "desc": "El sistema ha generado el borrador del contrato.",
        "role": StepRole.SYSTEM,
        "order": 1
    },
    {
        "key": "CONTRACT_SIGNATURE",
        "label": "Firma Digital",
        "desc": "Ambas partes han firmado el contrato de arras.",
        "role": StepRole.BOTH, # Usually auto-confirmed by system upon signature, but logically belongs to both
        "order": 2
    },
    {
        "key": "ARRAS_PAYMENT",
        "label": "Pago de Señal (Arras)",
        "desc": "Transferencia realizada y recibida.",
        "role": StepRole.BOTH, # Buyer confirms "Sent", Seller confirms "Received"
        "order": 3
    },
    {
        "key": "DOCUMENT_VERIFICATION",
        "label": "Verificación Documental",
        "desc": "Nota Simple y Certificados validados.",
        "role": StepRole.SYSTEM,
        "order": 4
    },
    {
        "key": "MORTGAGE_APPROVAL",
        "label": "Aprobación Hipotecaria",
        "desc": "El comprador confirma disposición de fondos.",
        "role": StepRole.BUYER,
        "order": 5
    },
    {
        "key": "NOTARY_ASSIGNMENT",
        "label": "Asignación Notario",
        "desc": "Notario seleccionado y cita agendada.",
        "role": StepRole.BOTH, # Or System if one assigns and other accepts. Let's say BOTH for consensus.
        "order": 6
    },
    {
        "key": "DEED_SIGNATURE",
        "label": "Firma Escritura Pública",
        "desc": "Cierre final ante notario.",
        "role": StepRole.BOTH,
        "order": 7
    }
]

class TimelineService:
    def __init__(self, db: Session):
        self.db = db

    def initialize_timeline(self, offer: PropertyOffer) -> List[TransactionStep]:
        """
        Creates the initial steps for a freshly ACCEPTED offer.
        Idempotent: if steps exist, returns them.
        """
        # Check if already exists
        existing = self.db.query(TransactionStep).filter(TransactionStep.offer_id == offer.id).all()
        if existing:
            return existing

        steps = []
        for cfg in STANDARD_TIMELINE_STEPS:
            step = TransactionStep(
                offer_id=offer.id,
                step_order=cfg["order"],
                step_key=cfg["key"],
                label=cfg["label"],
                description=cfg["desc"],
                required_role=cfg["role"],
                status=StepStatus.PENDING
            )
            self.db.add(step)
            steps.append(step)
        
        self.db.commit()
        logger.info(f"Timeline initialized for Offer {offer.id} with {len(steps)} steps.")
        return steps

    def confirm_step(self, step_id: int, role_requesting: str, metadata: dict = None) -> TransactionStep:
        """
        Processes a user confirmation (Check).
        role_requesting: 'BUYER' or 'SELLER' (derived from User)
        """
        step = self.db.query(TransactionStep).get(step_id)
        if not step:
            raise ValueError("Step not found")

        # Validation
        if step.status == StepStatus.COMPLETED:
            return step # Already done

        now = datetime.now(timezone.utc)
        start_metadata = step.metadata_json or {}
        
        # Mapping User Role to Action
        if role_requesting == "BUYER":
            if step.required_role not in [StepRole.BUYER, StepRole.BOTH]:
                raise PermissionError("Buyer cannot confirm this step")
            step.buyer_confirmed_at = now
            # Log in metadata
            start_metadata["buyer_log"] = metadata
            
        elif role_requesting == "SELLER":
            if step.required_role not in [StepRole.SELLER, StepRole.BOTH]:
                raise PermissionError("Seller cannot confirm this step")
            step.seller_confirmed_at = now
            start_metadata["seller_log"] = metadata
            
        else:
             raise ValueError("Invalid Role")

        step.metadata_json = start_metadata

        # Status Logic
        if step.required_role == StepRole.BOTH:
            if step.buyer_confirmed_at and step.seller_confirmed_at:
                step.status = StepStatus.COMPLETED
            elif step.buyer_confirmed_at or step.seller_confirmed_at:
                step.status = StepStatus.PARTIALLY_COMPLETED
        else:
            # Single role requirement
            step.status = StepStatus.COMPLETED

        self.db.commit()
        self.db.refresh(step)
        
        # Hito 15: Check for Auto-Closing
        # If this was the last pending step, trigger closing
        if step.status == StepStatus.COMPLETED:
            from backend.src.services.closing_service import ClosingService # Lazy import to avoid circular dependency
            try:
                if ClosingService.validate_closing_eligibility(self.db, step.offer_id):
                    ClosingService.execute_closing(self.db, step.offer_id)
            except Exception as e:
                logger.error(f"Auto-Closing Failed: {e}")
                
        return step

    def get_timeline(self, offer_id: int) -> List[TransactionStep]:
        return self.db.query(TransactionStep)\
            .filter(TransactionStep.offer_id == offer_id)\
            .order_by(TransactionStep.step_order.asc())\
            .all()

    def auto_complete_step(self, offer_id: int, step_key: str, system_note: str = None):
        """
        For system steps (e.g. Contract Generated, Signature Completed).
        """
        step = self.db.query(TransactionStep).filter(
            TransactionStep.offer_id == offer_id,
            TransactionStep.step_key == step_key
        ).first()
        
        if step and step.status != StepStatus.COMPLETED:
            step.status = StepStatus.COMPLETED
            step.buyer_confirmed_at = datetime.now(timezone.utc) # Auto
            step.seller_confirmed_at = datetime.now(timezone.utc) # Auto
            if system_note:
                step.metadata_json = {"system_log": system_note}
            self.db.commit()
