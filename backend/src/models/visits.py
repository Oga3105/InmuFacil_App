from sqlalchemy import Column, Integer, Enum, DateTime, ForeignKey, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
from .enums import VisitStatus

class VisitWindow(Base):
    """
    Availability block defined by the Seller.
    e.g., "Saturday from 10:00 to 14:00"
    """
    __tablename__ = "visit_windows"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    property = relationship("Property", back_populates="visit_windows")
    
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=False)
    slot_duration_minutes = Column(Integer, default=20, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship to Appointments
    appointments = relationship("VisitAppointment", back_populates="window", cascade="all, delete-orphan")


class VisitAppointment(Base):
    """
    Specific slot booked by a Buyer within a Window.
    """
    __tablename__ = "visit_appointments"

    id = Column(Integer, primary_key=True, index=True)
    window_id = Column(Integer, ForeignKey("visit_windows.id"), nullable=False)
    window = relationship("VisitWindow", back_populates="appointments")
    
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    buyer = relationship("User", back_populates="appointments")
    
    start_time = Column(DateTime(timezone=True), nullable=False)
    status = Column(Enum(VisitStatus), default=VisitStatus.REQUESTED, nullable=False)
    
    # Filtering Questions (Hito Visits Refinement)
    q_solvency = Column(String, nullable=True) # "Financiación Aprobada", "Contado", "Hipoteca Pendiente"
    q_timeline = Column(String, nullable=True) # "Inmediato", "3-6 meses", "Solo mirando"
    q_maturity = Column(String, nullable=True) # "Primera visita", "He visto 10 pisos", "Indeciso"
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
