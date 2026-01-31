
import pytest
from datetime import datetime, timedelta
from backend.src.services.contract_service import ContractGenerator
from backend.src.models.users import User, UserType
from backend.src.models.properties import Property
from backend.src.models.offers import PropertyOffer, OfferStatus, ContractAnalysis
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
from fastapi.testclient import TestClient
from backend.main import app
from backend.src.config.database import get_db
from backend.src.routes.auth import get_current_user

# --- UNIT TESTS ---

def test_contract_generator_output():
    """
    Verifies that ContractGenerator produces a valid PDF stream.
    """
    pdf_bytes = ContractGenerator.generate_arras_draft(
        buyer_name="Juan Comprador",
        buyer_dni="12345678A",
        seller_name="Maria Vendedora",
        seller_dni="87654321B",
        property_address="Calle Mayor 1",
        property_registry_ref="REF123",
        price_total=100000.0,
        deposit_amount=10000.0,
        limit_date=datetime.now()
    )
    
    # Check Magic Bytes for PDF
    assert pdf_bytes.startswith(b"%PDF")
    
    # Check Content (Note: PDF binary search is tricky due to compression,
    # but ReportLab standard fonts usually leave text accessible or we check length)
    assert len(pdf_bytes) > 1000 # Should be substantial

# --- INTEGRATION TESTS ---

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_contracts.db"
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

def test_download_endpoint_security(client, db_session):
    # 1. Setup Data
    seller = User(email="seller@test.com", hashed_password="pw", full_name="Seller")
    buyer = User(email="buyer@test.com", hashed_password="pw", full_name="Buyer")
    intruder = User(email="thief@test.com", hashed_password="pw", full_name="Intruder")
    db_session.add_all([seller, buyer, intruder])
    db_session.commit()
    
    prop = Property(
        owner_id=seller.id, 
        title="Piso", 
        price=100000, 
        location="Calle 1, Madrid",
        surface_area=100.0,
        property_type="piso",
        operation_type="venta"
    )
    db_session.add(prop)
    db_session.commit()
    
    offer = PropertyOffer(
        buyer_id=buyer.id, 
        property_id=prop.id, 
        amount=100000, 
        status=OfferStatus.ACCEPTED
    )
    db_session.add(offer)
    db_session.commit()
    
    # 2. Test Intruder Access (Should Fail 403)
    app.dependency_overrides[get_current_user] = lambda: intruder
    response = client.get(f"/contracts/arras/draft/{offer.id}")
    assert response.status_code == 403
    
    # 3. Test Authorized Access (Should Succeed 200)
    app.dependency_overrides[get_current_user] = lambda: buyer
    response = client.get(f"/contracts/arras/draft/{offer.id}")
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"

def test_contract_questionnaire_flow(client, db_session):
    # 1. Setup Data
    user = User(email="legal@test.com", hashed_password="pw", full_name="LegalUser")
    db_session.add(user)
    db_session.commit()
    
    prop = Property(owner_id=user.id, title="LegalProp", price=200000, 
                   location="Legal St", surface_area=90, property_type="piso", operation_type="venta")
    db_session.add(prop)
    db_session.commit()
    
    offer = PropertyOffer(buyer_id=user.id, property_id=prop.id, amount=200000, status=OfferStatus.ACCEPTED)
    # Note: Buyer is same as owner for simplicity in setup, logic allows both to edit
    db_session.add(offer)
    db_session.commit()
    
    app.dependency_overrides[get_current_user] = lambda: user

    # 2. Update Details
    details = {
        "has_foreign_funds": True,
        "is_cuerpo_cierto": False,
        "community_fees_monthly": 150.0,
        "delivery_condition": "Con inquilinos"
    }
    response = client.put(f"/contracts/offers/{offer.id}/details", json=details)
    assert response.status_code == 200
    data = response.json()
    assert data["has_foreign_funds"] is True
    assert data["community_fees_monthly"] == 150.0

    # 3. Generate Contract with New Details
    response_pdf = client.get(f"/contracts/arras/draft/{offer.id}")
    assert response_pdf.status_code == 200
    # Ideally checking PDF content, but byte check confirms generation with new path
    assert len(response_pdf.content) > 1000
    assert response_pdf.content.startswith(b"%PDF")

def test_download_endpoint_status_check(client, db_session):
    # Setup Offer in PENDING status
    seller = User(email="s2@test.com", hashed_password="pw", full_name="Seller 2")
    buyer = User(email="b2@test.com", hashed_password="pw", full_name="Buyer 2")
    db_session.add_all([seller, buyer])
    db_session.commit()
    
    prop = Property(
        owner_id=seller.id, 
        title="Piso 2",
        price=100, 
        location="X, Y",
        surface_area=50.0
    )
    db_session.add(prop)
    db_session.commit()
    
    offer = PropertyOffer(
        buyer_id=buyer.id, property_id=prop.id, amount=100, 
        status=OfferStatus.PENDING # Not Accepted yet
    )
    db_session.add(offer)
    db_session.commit()
    
    app.dependency_overrides[get_current_user] = lambda: buyer
    response = client.get(f"/contracts/arras/draft/{offer.id}")
    
    assert response.status_code == 400 # Bad Request (Not Accepted)

def test_custom_contract_upload_ai(client, db_session):
    # 1. Setup Data
    user = User(email="upload@test.com", hashed_password="pw", full_name="Uploader")
    db_session.add(user)
    db_session.commit()
    
    prop = Property(owner_id=user.id, title="UploadProp", price=300000, 
                   location="Upload St", surface_area=100)
    db_session.add(prop)
    db_session.commit()
    
    offer = PropertyOffer(buyer_id=user.id, property_id=prop.id, amount=300000, status=OfferStatus.ACCEPTED)
    db_session.add(offer)
    db_session.commit()
    
    app.dependency_overrides[get_current_user] = lambda: user
    
    # 2. Prepare File and Form Data
    file_content = b"This is a dummy contract for testing AI analysis."
    files = {"file": ("contract.txt", file_content, "text/plain")}
    data = {"accept_ai_processing": True}
    
    # 3. Call Endpoint
    response = client.post(f"/contracts/offers/{offer.id}/upload", files=files, data=data)
    
    # 4. Assertions
    assert response.status_code == 200
    json_resp = response.json()
    
    # Check Analysis Structure
    assert "risk_score" in json_resp
    assert "cost_estimate" in json_resp
    assert json_resp["cost_estimate"] > 0
    assert "disclaimer" in json_resp
    
    # Check DB Storage (Liability)
    analysis = db_session.query(ContractAnalysis).filter(ContractAnalysis.offer_id == offer.id).first()
    assert analysis is not None
    assert analysis.role == "BUYER" # Because user is buyer
    assert analysis.consent_timestamp is not None
    assert analysis.disclaimer_version == "v1.0"
    
    # Check File Path updated (Mock logic assumes local saving, but test uses separate DB. 
    # File saving is FS operation. We should verify offer.custom_contract_path)
    db_session.refresh(offer)
    assert offer.custom_contract_path is not None
    assert "contract.txt" in offer.custom_contract_path

