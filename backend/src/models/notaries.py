from sqlalchemy import Column, Integer, String, Enum as SAEnum
from .base import Base
import enum

class NotaryIntegrationType(str, enum.Enum):
    EMAIL = "EMAIL"
    API_MOCK = "API_MOCK"

class Notary(Base):
    __tablename__ = "notaries"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    address_line = Column(String, nullable=False)
    city = Column(String, nullable=False)
    email = Column(String, nullable=False, unique=True)
    phone = Column(String, nullable=False)
    integration_type = Column(SAEnum(NotaryIntegrationType), default=NotaryIntegrationType.EMAIL)
