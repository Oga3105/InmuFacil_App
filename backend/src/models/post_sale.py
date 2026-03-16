from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SAEnum, UniqueConstraint
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

    doc_type    = Column(SAEnum(PostSaleDocType, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    filename    = Column(String, nullable=False)
    file_path   = Column(String, nullable=False)
    file_size   = Column(Integer, nullable=True)

    created_at  = Column(DateTime(timezone=True), server_default=func.now())


class PostSaleDocFlag(Base):
    """
    Non-file status markers set by the Seller for a doc type.
    Flag values: 'in_person' | 'not_applicable'
    One flag per (offer_id, doc_type) — upserted on set.
    """
    __tablename__ = "post_sale_doc_flags"
    __table_args__ = (
        UniqueConstraint("offer_id", "doc_type", name="uix_post_sale_doc_flags"),
    )

    id         = Column(Integer, primary_key=True, index=True)
    offer_id   = Column(Integer, ForeignKey("offers.id"), nullable=False, index=True)
    doc_type   = Column(SAEnum(PostSaleDocType, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    flag       = Column(String, nullable=False)   # "in_person" | "not_applicable"
    set_by     = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
