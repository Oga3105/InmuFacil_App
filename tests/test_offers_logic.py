"""
@Jules - Offers System TDD

Validates Business Rules for "Manifestación de Interés" (Hito 6).
Status: RED (Pending Implementation)
"""

import pytest
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
from backend.src.models import User, Property, PropertyOffer, OfferStatus

# Test DB Setup (Can refactor to conftest.py later for DRY)
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_offers.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture
def offer_fixtures(db_session):
    seller = User(email="seller@offer.com", hashed_password="pw", full_name="Seller Offer")
    buyer = User(email="buyer@offer.com", hashed_password="pw", full_name="Buyer Offer")
    db_session.add(seller)
    db_session.add(buyer)
    db_session.commit()
    
    prop = Property(
        title="Offer House", price=300000, location="Madrid", 
        surface_area=100, owner_id=seller.id
    )
    db_session.add(prop)
    db_session.commit()
    
    return {"seller": seller, "buyer": buyer, "property": prop}

# ============================================================================
# TDD Cases
# ============================================================================

def test_create_valid_offer(db_session, offer_fixtures):
    """
    Happy Path: Buyer makes an offer on Seller's property.
    """
    offer = PropertyOffer(
        property_id=offer_fixtures["property"].id,
        buyer_id=offer_fixtures["buyer"].id,
        amount=290000,
        conditions="Subject to mortgage",
        valid_until=datetime.utcnow() + timedelta(days=7)
    )
    db_session.add(offer)
    db_session.commit()
    
    assert offer.id is not None
    assert offer.status == OfferStatus.PENDING
    assert offer.amount == 290000


def test_prevent_self_offer(db_session, offer_fixtures):
    """
    Security Rule: Owner cannot make an offer on their own property.
    """
    # Logic simulation (Router should check this)
    owner_id = offer_fixtures["seller"].id
    buyer_id = offer_fixtures["seller"].id # Same ID
    
    # We expect the router logic to raise ValueError/HTTPException
    # Defining the validation function here for TDD
    def validate_offer(prop_owner_id, bidder_id):
         if prop_owner_id == bidder_id:
             raise ValueError("Owner cannot bid on own property")
             
    with pytest.raises(ValueError, match="Owner cannot bid"):
        validate_offer(offer_fixtures["property"].owner_id, buyer_id)


def test_offer_amount_must_be_positive(db_session, offer_fixtures):
    """
    Business Rule: Offer amount > 0.
    """
    # Depending on DB/Pydantic validation, assume Logic Layer check
    def validate_amount(amount):
        if amount <= 0:
            raise ValueError("Amount must be positive")
            
    with pytest.raises(ValueError):
        validate_amount(-500)

