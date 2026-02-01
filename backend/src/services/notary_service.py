
from sqlalchemy.orm import Session
from typing import List, Optional
from backend.src.models.notaries import Notary, NotaryIntegrationType
from backend.src.models.offers import PropertyOffer
from backend.src.models.enums import NotaryStatus, OfferStatus

class NotaryService:
    def __init__(self, db: Session):
        self.db = db

    def list_notaries(self) -> List[Notary]:
        return self.db.query(Notary).all()

    def create_notary(self, name: str, address: str, city: str, email: str, phone: str) -> Notary:
        notary = Notary(
            name=name,
            address_line=address,
            city=city,
            email=email,
            phone=phone,
            integration_type=NotaryIntegrationType.EMAIL
        )
        self.db.add(notary)
        self.db.commit()
        self.db.refresh(notary)
        return notary

    def assign_notary(self, offer_id: int, notary_id: int) -> PropertyOffer:
        offer = self.db.query(PropertyOffer).get(offer_id)
        if not offer:
            raise ValueError("Offer not found")
        
        # Validation: Offer must be SIGNED before Notary
        if offer.status != OfferStatus.SIGNED:
            raise ValueError("Cannot assign notary to an unsigned offer")

        notary = self.db.query(Notary).get(notary_id)
        if not notary:
            raise ValueError("Notary not found")

        offer.notary_id = notary.id
        offer.notary_status = NotaryStatus.ASSIGNED
        self.db.commit()
        self.db.refresh(offer)
        return offer
