"""
BuyerSolvency model — Pasaporte de Solvencia Consciente
Stores the buyer's self-declared financial qualification data.
All sensitive fields (pre_approval_pdf_url) are AES-256-GCM encrypted at rest.
Documents are subject to 90-day automatic purge (expires_at).
"""
from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, Float, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
from .enums import PaymentMethod, StressIndex, SolvencyLevel


class BuyerSolvency(Base):
    """
    One record per buyer. UPSERT semantics — re-submitting the wizard
    overwrites the previous declaration.
    """
    __tablename__ = "buyer_solvency"

    id = Column(Integer, primary_key=True, index=True)
    buyer_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    # --- Disclaimer (Layer 1) ---
    terms_accepted_at = Column(DateTime(timezone=True), nullable=True)
    terms_version_id = Column(String(20), nullable=True, default="v1.0")

    # --- Awareness test (Layer 2 — Devil's Advocate) ---
    knows_extra_costs = Column(Boolean, nullable=True)   # ITP/IVA/Notaria awareness
    debt_ratio = Column(Float, nullable=True)            # 0.0..1.0 (monthly_debt/net_income)
    has_emergency_fund = Column(Boolean, nullable=True)

    # --- Solvency declaration (Layer 3) ---
    payment_method = Column(Enum(PaymentMethod), nullable=True)
    has_initial_savings = Column(Boolean, nullable=True)
    has_pre_approval = Column(Boolean, nullable=True)
    # AES-256-GCM encrypted URL — decrypted only for the buyer themselves
    pre_approval_pdf_url_encrypted = Column(String, nullable=True)

    # --- Computed scores ---
    stress_index = Column(Enum(StressIndex), nullable=True)
    solvency_level = Column(Enum(SolvencyLevel), nullable=True)

    # --- Metadata ---
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    # Auto-purge: set to created_at + 90 days when record is created
    expires_at = Column(DateTime(timezone=True), nullable=True)

    buyer = relationship("User", backref="solvency", foreign_keys=[buyer_id])
