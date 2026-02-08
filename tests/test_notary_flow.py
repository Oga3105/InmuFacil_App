
import pytest
import os
import zipfile
from datetime import datetime
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from backend.main import app
from backend.src.models.base import Base
from backend.src.config.database import get_db
from backend.src.routes.auth import get_current_user

from backend.src.models.users import User, UserType
from backend.src.models.properties import Property
from backend.src.models.offers import PropertyOffer
from backend.src.models.enums import OfferStatus, NotaryStatus
from backend.src.models.notaries import Notary

# --- SETUP ---
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_notary.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        # Pre-seed Notaries
        notary = Notary(name="Test Notary", address_line="Addr", city="City", email="test@not.com", phone="123")
        db.add(notary)
        db.commit()
        yield db
    finally:
        db.close()
        # Clean up file created by Base.metadata if needed, or drop all here
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

def test_notary_assignment_flow(client, db_session):
    """
    Test: Assign Notary -> Status Update -> Generate Dossier
    """
    # 1. Setup Data
    user = User(email="user@test.com", hashed_password="pw", full_name="User Test")
    db_session.add(user)
    db_session.commit()
    
    prop = Property(owner_id=user.id, title="Prop", price=100, location="Loc", surface_area=1)
    db_session.add(prop)
    db_session.commit()
    
    # Offer must be SIGNED for notary assignment
    offer = PropertyOffer(
        property_id=prop.id, 
        buyer_id=user.id, # Simplified for test
        amount=100, 
        status=OfferStatus.SIGNED,
        signature_token="used_token"
    )
    db_session.add(offer)
    db_session.commit()
    
    notary = db_session.query(Notary).first()
    
    # 2. Assign Notary
    app.dependency_overrides[get_current_user] = lambda: user
    
    payload = {"offer_id": offer.id, "notary_id": notary.id}
    res = client.post("/notaries/assign", json=payload)
    assert res.status_code == 200, res.text
    assert res.json() is True
    
    db_session.refresh(offer)
    assert offer.notary_id == notary.id
    assert offer.notary_status == NotaryStatus.ASSIGNED

    # 3. Generate Dossier (Hito 14 + Manifest)
    # Mocking file system operations is hard in Integ test, usually we test logic unit.
    # But here we let it create temp files in test dir.
    
    res_down = client.get(f"/notaries/dossier/{offer.id}")
    assert res_down.status_code == 200
    assert res_down.headers["content-type"] == "application/zip"
    
    # Verify Content
    # We can save bytes to a temp file and inspect the zip
    zip_path = f"test_dossier_{offer.id}.zip"
    with open(zip_path, "wb") as f:
        f.write(res_down.content)
        
    try:
        with zipfile.ZipFile(zip_path, 'r') as zipf:
            files = zipf.namelist()
            assert "MANIFEST.txt" in files
            assert "contrato_arras_firmado.pdf" in files
            
            # Check Manifest Content
            manifest = zipf.read("MANIFEST.txt").decode("utf-8")
            assert "MANIFESTO DE SEGURIDAD" in manifest
            assert "contrato_arras_firmado.pdf" in manifest
    finally:
        if os.path.exists(zip_path):
            os.remove(zip_path)

def test_cannot_assign_unsigned_offer(client, db_session):
    # Setup
    user = User(email="fail@test.com", hashed_password="pw", full_name="Fail User")
    db_session.add(user)
    db_session.commit()
    
    prop = Property(owner_id=user.id, title="Prop", price=100, location="Loc", surface_area=1)
    db_session.add(prop)
    
    offer = PropertyOffer(property_id=prop.id, buyer_id=user.id, amount=100, status=OfferStatus.ACCEPTED) # Not SIGNED
    db_session.add(offer)
    db_session.commit()
    
    notary = db_session.query(Notary).first()
    
    app.dependency_overrides[get_current_user] = lambda: user
    
    payload = {"offer_id": offer.id, "notary_id": notary.id}
    res = client.post("/notaries/assign", json=payload)
    assert res.status_code == 400
    assert "unsigned" in res.text
