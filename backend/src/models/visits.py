from sqlalchemy import Column, Integer, Enum, DateTime, ForeignKey, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base
from .enums import VisitStatus

class VisitWindow(Base):
    """Availability block defined by the Seller."""
    __tablename__ = "visit_windows"

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"), nullable=False)
    property = relationship("Property", back_populates="visit_windows")

    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=False)
    slot_duration_minutes = Column(Integer, default=20, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    appointments = relationship("VisitAppointment", back_populates="window", cascade="all, delete-orphan")


class VisitAppointment(Base):
    """Specific slot booked by a Buyer within a Window."""
    __tablename__ = "visit_appointments"

    id = Column(Integer, primary_key=True, index=True)
    window_id = Column(Integer, ForeignKey("visit_windows.id"), nullable=False)
    window = relationship("VisitWindow", back_populates="appointments")

    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    buyer = relationship("User", back_populates="appointments")

    start_time = Column(DateTime(timezone=True), nullable=False)
    status = Column(Enum(VisitStatus, native_enum=False), default=VisitStatus.REQUESTED, nullable=False)

    q_solvency = Column(String, nullable=True)
    q_timeline = Column(String, nullable=True)
    q_maturity = Column(String, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
