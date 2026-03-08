from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.sql import func
from .base import Base
import enum


class PostSaleDocType(str, enum.Enum):
    ELECTRICITY = "electricity"
    WATER       = "water"
    GAS         = "gas"
    IBI         = "ibi"
    COMMUNITY   = "community"


class PostSaleDocument(Base):
    """
    Documents uploaded by the Seller during the Post-Sale phase.
    Accessible to the Buyer only after DEED_SIGNATURE step is COMPLETED.
    """
    __tablename__ = "post_sale_documents"

    id          = Column(Integer, primary_key=True, index=True)
    offer_id    = Column(Integer, ForeignKey("offers.id"), nullable=False, index=True)
    uploaded_by = Column(Integer, ForeignKey("users.id"), nullable=False)

    doc_type    = Column(SAEnum(PostSaleDocType), nullable=False)
    filename    = Column(String, nullable=False)
    file_path   = Column(String, nullable=False)
    file_size   = Column(Integer, nullable=True)

    created_at  = Column(DateTime(timezone=True), server_default=func.now())
