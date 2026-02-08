from sqlalchemy import Column, Integer, String, DateTime, func
from .base import Base

class Lead(Base):
    __tablename__ = "leads"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    source = Column(String, default="404_page")
