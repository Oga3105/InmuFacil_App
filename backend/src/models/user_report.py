"""
UserReport model for the Community Shield P2P reporting system.

Stores reports from users who suspect another user is a professional
real estate agent operating on the P2P platform.
"""

import enum
from sqlalchemy import Column, Integer, String, Enum, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base


class ReportCategory(str, enum.Enum):
    """Categories for user reports against suspected professionals."""
    PROFESIONAL_CAMUFLADO = "profesional_camuflado"
    PIDE_COMISION = "pide_comision"
    DATOS_INEXACTOS = "datos_inexactos"


class UserReport(Base):
    """
    Tracks reports filed by users against suspected professional agents.

    Each report links a reporter to a reported user with a category
    and optional description. The system enforces one report per
    reporter/reported pair.
    """
    __tablename__ = "user_reports"

    id = Column(Integer, primary_key=True, index=True)
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    reported_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    reason_category = Column(
        Enum(ReportCategory, native_enum=False),
        nullable=False,
    )
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    reporter = relationship("User", foreign_keys=[reporter_id])
    reported = relationship("User", foreign_keys=[reported_id])
