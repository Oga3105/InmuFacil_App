from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from .base import Base


class UserLifestyleProfile(Base):
    __tablename__ = "user_lifestyle_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Enum selections stored as strings (match Flutter enum names)
    lifestyle_pace = Column(String, nullable=True)
    work_style = Column(String, nullable=True)
    mobility_style = Column(String, nullable=True)
    sleep_sensitivity = Column(String, nullable=True)
    green_needs = Column(String, nullable=True)
    profile_type = Column(String, nullable=True)

    # Slider values (0.0 to 1.0)
    natural_light_weight = Column(Float, nullable=True, default=0.5)
    social_weight = Column(Float, nullable=True, default=0.5)
    ready_to_live_weight = Column(Float, nullable=True, default=0.5)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", backref="lifestyle_profile")

    __table_args__ = (
        UniqueConstraint("user_id", name="_user_lifestyle_uc"),
    )
