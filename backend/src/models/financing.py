from sqlalchemy import Column, Integer, String, DECIMAL, ForeignKey, DateTime, Enum, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
import enum

class EmploymentStatus(str, enum.Enum):
    INDEFINIDO = "indefinido"
    TEMPORAL = "temporal"
    AUTONOMO = "autonomo"
    FUNCIONARIO = "funcionario"
    PENSIONISTA = "pensionista"
    DESEMPLEADO = "desempleado"

class MortgageProfile(Base):
    """
    Financial Profile of a User (Sensitive Data).
    Used to calculate solvency score and simulate mortgages.
    """
    __tablename__ = "mortgage_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    user = relationship("User", back_populates="mortgage_profile")
    
    # Income & Savings
    monthly_net_income = Column(DECIMAL(12, 2), nullable=False)
    monthly_debts = Column(DECIMAL(12, 2), default=0) # Other loans
    savings_available = Column(DECIMAL(12, 2), default=0)
    
    # Employment
    employment_status = Column(Enum(EmploymentStatus), nullable=False)
    contract_years = Column(Integer, default=0) # Seniority
    age = Column(Integer, nullable=False)
    
    # Updated
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())


class MortgageSimulation(Base):
    """
    Record of mortgage simulations run by the user or their advisor.
    """
    __tablename__ = "mortgage_simulations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    user = relationship("User", back_populates="simulations")
    
    # Target Property (Optional, can simulate generically)
    target_property_value = Column(DECIMAL(12, 2), nullable=False)
    asked_amount = Column(DECIMAL(12, 2), nullable=False)
    years = Column(Integer, default=30)
    
    # Result Snapshot
    solvency_score = Column(Integer) # 0-100 (Internal)
    is_viable_internal = Column(Boolean) # Based on max debt ratio (e.g. 35%)
    
    # JSON with aggregated offers from Mock (iAhorro, BBVA, etc.)
    offers_snapshot = Column(String) # Stored as JSON Text
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
