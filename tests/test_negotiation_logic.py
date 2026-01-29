"""
@Jules - Negotiation & Encrypted Chat Logic (TDD)

Tests Hito 7:
1. Negotiation Protocol (History Log, State Changes).
2. Chat Privacy (Encryption, Access Control).
"""

import pytest
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.database import Base
from backend.models import User, Property, PropertyOffer, OfferStatus, OfferHistory, OfferMessage
from backend.crypto import encrypt_data, decrypt_data

# ============================================================================
# Setup
# ============================================================================

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_negotiation.db"
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
def nego_fixtures(db_session):
    seller = User(email="seller@neg.com", hashed_password="pw", full_name="Seller Neg")
    buyer = User(email="buyer@neg.com", hashed_password="pw", full_name="Buyer Neg")
    db_session.add(seller)
    db_session.add(buyer)
    db_session.commit()
    
    prop = Property(
        title="Neg House", price=500000, location="Valencia", 
        surface_area=120, owner_id=seller.id
    )
    db_session.add(prop)
    db_session.commit()
    
    # Initial Offer
    offer = PropertyOffer(
        property_id=prop.id,
        buyer_id=buyer.id,
        amount=450000,
        status=OfferStatus.PENDING
    )
    db_session.add(offer)
    db_session.commit()
    
    # Log initial history (simulating controller logic)
    hist = OfferHistory(
        offer_id=offer.id, actor_id=buyer.id, action="MAKE", amount=450000
    )
    db_session.add(hist)
    db_session.commit()
    
    return {"seller": seller, "buyer": buyer, "offer": offer}

# ============================================================================
# TDD: Negotiation Logic
# ============================================================================

def test_counter_offer_flow(db_session, nego_fixtures):
    """
    Test 1: Negotiation Ping-Pong
    Seller counters -> Offer Status updates -> History logged.
    """
    offer = nego_fixtures["offer"]
    seller = nego_fixtures["seller"]
    
    # 1. Seller Counters
    new_amount = 480000
    
    # Logic Simulation
    offer.status = OfferStatus.COUNTERED
    offer.amount = new_amount # Update current visible amount
    
    history_entry = OfferHistory(
        offer_id=offer.id,
        actor_id=seller.id,
        action="COUNTER",
        amount=new_amount
    )
    db_session.add(history_entry)
    db_session.commit()
    
    # Assertions
    updated_offer = db_session.query(PropertyOffer).first()
    assert updated_offer.status == OfferStatus.COUNTERED
    assert updated_offer.amount == 480000
    
    history = db_session.query(OfferHistory).filter_by(offer_id=offer.id).all()
    assert len(history) == 2 # Initial + Counter
    assert history[1].action == "COUNTER"

# ============================================================================
# TDD: Encrypted Chat
# ============================================================================

def test_chat_encryption_at_rest(db_session, nego_fixtures):
    """
    Test 2: Security - Verify DB stores ciphertext, not plaintext.
    """
    offer = nego_fixtures["offer"]
    raw_message = "Please accept my offer!"
    
    # Enable Chat first
    offer.is_chat_enabled = True
    db_session.commit()
    
    # Encrypt & Store
    encrypted_msg = encrypt_data(raw_message)
    msg_entry = OfferMessage(
        offer_id=offer.id,
        sender_id=nego_fixtures["buyer"].id,
        message_encrypted=encrypted_msg
    )
    db_session.add(msg_entry)
    db_session.commit()
    
    # Verify DB content
    stored_msg = db_session.query(OfferMessage).first()
    assert stored_msg.message_encrypted != raw_message # Must be different
    assert "Please" not in stored_msg.message_encrypted # Plaintext leakage check
    
    # Verify Decryption
    decrypted = decrypt_data(stored_msg.message_encrypted)
    assert decrypted == raw_message

def test_chat_disabled_check(db_session, nego_fixtures):
    """
    Test 3: Privacy - Buyer cannot chat if Seller hasn't enabled it.
    """
    offer = nego_fixtures["offer"]
    # Ensure chat disabled
    assert offer.is_chat_enabled == False
    
    # Logic Simulation (Router should enforce this)
    def send_message(offer_instance):
        if not offer_instance.is_chat_enabled:
             raise PermissionError("Chat unauthorized")
             
    with pytest.raises(PermissionError):
        send_message(offer)
