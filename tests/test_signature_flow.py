
import pytest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from backend.main import app
from backend.src.models.base import Base
from backend.src.config.database import get_db
from backend.src.routes.auth import get_current_user

from backend.src.models.users import User, UserType
from backend.src.models.properties import Property
from backend.src.models.offers import PropertyOffer, OfferStatus as ProposalStatus, OfferStatus
# Note: OfferStatus imported twice? alias ProposalStatus not needed if we use OfferStatus directly.

# --- SETUP ---
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_signature.db"
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

@pytest.fixture(scope="function")
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass
    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()

# --- TESTS ---

def test_signature_lifecycle(client, db_session):
    """
    Test the full lifecycle of a digital signature (Sync TestClient).
    """
    # 1. Setup Data
    # Create Seller
    seller = User(email="seller@sig.com", hashed_password="pw", full_name="Seller Sig")
    db_session.add(seller)
    
    # Create Buyer
    buyer = User(email="buyer@sig.com", hashed_password="pw", full_name="Buyer Sig")
    db_session.add_all([seller, buyer])
    db_session.commit()
    
    # Create Property
    prop = Property(
        owner_id=seller.id,
        title="Signature Prop",
        price=100000.0,
        location="Loc",
        surface_area=100.0
    )
    db_session.add(prop)
    db_session.commit()
    
    # Create Offer (Accepted)
    offer = PropertyOffer(
        property_id=prop.id,
        buyer_id=buyer.id,
        amount=95000.0,
        status=OfferStatus.ACCEPTED
    )
    db_session.add(offer)
    db_session.commit()
    
    # 2. Action: Request Signature (As Buyer)
    app.dependency_overrides[get_current_user] = lambda: buyer
    
    res_req = client.post(f"/contracts/{offer.id}/sign/request")
    assert res_req.status_code == 200, res_req.text
    data_req = res_req.json()
    assert data_req["status"] == "signing_pending"
    token = data_req["token"]
    assert token is not None

    # 3. Verify DB State (Reload from DB)
    db_session.refresh(offer)
    assert offer.status == OfferStatus.SIGNING_PENDING
    assert offer.signature_token == token

    # 4. Action: Simulate Signing (GET /contracts/sign/simulate/{token})
    # No auth required for simulation click (public link)
    res_sign = client.get(f"/contracts/sign/simulate/{token}")
    assert res_sign.status_code == 200
    data_sign = res_sign.json()
    assert data_sign["new_status"] == "signed"
    assert "contracts/signed" in data_sign.get("contract_url", "")

    # 5. Verify DB State Final
    db_session.refresh(offer)
    assert offer.status == OfferStatus.SIGNED
    assert offer.signature_token is None # Token cleared

def test_signature_security(client, db_session):
    """
    Verify security constraints.
    """
    # 1. Invalid Token
    res = client.get("/contracts/sign/simulate/INVALID_TOKEN_123")
    assert res.status_code == 404
    
    # 2. Unauthorized Request (User not in offer)
    # Create random offer 
    
    intruder = User(email="intruder@sig.com", hashed_password="pw", full_name="Intruder")
    owner = User(email="owner@sig.com", hashed_password="pw", full_name="Owner")
    db_session.add_all([intruder, owner])
    db_session.commit()
    
    prop = Property(owner_id=owner.id, title="Unauthorized", price=9, location="X", surface_area=1)
    db_session.add(prop)
    db_session.commit()
    
    offer = PropertyOffer(property_id=prop.id, buyer_id=owner.id, amount=1, status=OfferStatus.ACCEPTED) 
    # Buyer is Owner just for simplicity of FK, doesn't matter, intruder is neither
    db_session.add(offer)
    db_session.commit()
    
    app.dependency_overrides[get_current_user] = lambda: intruder
    
    res_fail = client.post(f"/contracts/{offer.id}/sign/request")
    assert res_fail.status_code == 403 # Forbidden
