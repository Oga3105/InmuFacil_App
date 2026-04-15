"""
BuyerSolvency model — Pasaporte de Solvencia Consciente
All sensitive fields are AES-256-GCM encrypted at rest.
Documents subject to 90-day automatic purge (expires_at).
"""
from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, Float, ForeignKey, LargeBinary
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
from .enums import PaymentMethod, StressIndex, SolvencyLevel


class BuyerSolvency(Base):
    """One record per buyer. UPSERT semantics."""
    __tablename__ = "buyer_solvency"

    id = Column(Integer, primary_key=True, index=True)
    buyer_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    terms_accepted_at = Column(DateTime(timezone=True), nullable=True)
    terms_version_id = Column(String(20), nullable=True, default="v1.0")

    knows_extra_costs = Column(Boolean, nullable=True)
    debt_ratio = Column(Float, nullable=True)
    has_emergency_fund = Column(Boolean, nullable=True)

    payment_method = Column(Enum(PaymentMethod, native_enum=False), nullable=True)
    has_initial_savings = Column(Boolean, nullable=True)
    has_pre_approval = Column(Boolean, nullable=True)
    pre_approval_pdf_url_encrypted = Column(String, nullable=True)

    is_multi_buyer = Column(Boolean, nullable=False, default=False, server_default="false")

    net_monthly_income_enc = Column(String, nullable=True)
    total_savings_enc = Column(String, nullable=True)
    total_monthly_debt_enc = Column(String, nullable=True)

    second_buyer_name_enc = Column(String, nullable=True)
    second_buyer_dni_enc = Column(String, nullable=True)
    second_buyer_email_enc = Column(String, nullable=True)
    second_buyer_verified_at = Column(DateTime(timezone=True), nullable=True)
    second_buyer_status = Column(String(20), nullable=True)
    second_buyer_rejection_reason = Column(String, nullable=True)
    second_buyer_dni_hmac = Column(String(64), nullable=True)

    second_buyer_front_data = Column(LargeBinary, nullable=True)
    second_buyer_front_content_type = Column(String(100), nullable=True)
    second_buyer_back_data = Column(LargeBinary, nullable=True)
    second_buyer_back_content_type = Column(String(100), nullable=True)
    second_buyer_selfie_data = Column(LargeBinary, nullable=True)
    second_buyer_selfie_content_type = Column(String(100), nullable=True)

    stress_index = Column(Enum(StressIndex, native_enum=False), nullable=True)
    solvency_level = Column(Enum(SolvencyLevel, native_enum=False), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)

    buyer = relationship("User", backref="solvency", foreign_keys=[buyer_id])
