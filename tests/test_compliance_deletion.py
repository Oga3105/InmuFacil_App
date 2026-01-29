"""
@Jules - Integration Tests for Document Deletion Policy
"""
import pytest
from fastapi.testclient import TestClient
from backend.main import app
from backend.models import Property, User, PropertyDocument, DocumentType, PropertyStatus
from backend.database import get_db, Base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.security import create_access_token

# Setup Test DB
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_deletion_integ.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

@pytest.fixture(scope="function")
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def auth_headers(setup_db):
    db = TestingSessionLocal()
    # Create Owner
    owner = User(
        email="owner@delete.com", 
        hashed_password="pw", 
        full_name="Owner", 
        is_active=True
    )
    db.add(owner)
    db.commit()
    db.refresh(owner)
    
    # Create Property
    prop = Property(
        owner_id=owner.id, title="DelProp", price=100, 
        location="Loc", surface_area=50, status=PropertyStatus.PUBLISHED
    )
    db.add(prop)
    db.commit()
    db.refresh(prop)
    
    token = create_access_token(data={"sub": owner.email})
    db.close()
    return {"Authorization": f"Bearer {token}", "prop_id": prop.id, "owner_id": owner.id}

# Helper for mocking os.remove
from unittest.mock import patch

@pytest.fixture
def mock_os_remove():
    with patch("os.remove") as mock:
        yield mock

def test_delete_pending_document(auth_headers, mock_os_remove):
    db = TestingSessionLocal()
    # Create Pending Doc
    doc = PropertyDocument(
        property_id=auth_headers["prop_id"],
        doc_type=DocumentType.NOTA_SIMPLE,
        filename="pending.pdf",
        file_path="dummy_path.enc",
        is_encrypted=True,
        status="pending"
    )
    db.add(doc)
    db.commit()
    doc_id = doc.id
    db.close()
    
    # Action: Delete
    response = client.delete(
         f"/properties/{auth_headers['prop_id']}/documents/{doc_id}",
         headers={"Authorization": auth_headers["Authorization"]}
    )
    
    assert response.status_code == 204
    
    # Verify DB
    db = TestingSessionLocal()
    deleted = db.query(PropertyDocument).filter_by(id=doc_id).first()
    assert deleted is None
    db.close()

def test_delete_verified_document_forbidden(auth_headers):
    db = TestingSessionLocal()
    # Create Verified Doc
    doc = PropertyDocument(
        property_id=auth_headers["prop_id"],
        doc_type=DocumentType.RECIBO_IBI,
        filename="verified.pdf",
        file_path="dummy_path_v.enc",
        is_encrypted=True,
        status="verified"
    )
    db.add(doc)
    db.commit()
    doc_id = doc.id
    db.close()
    
    # Action: Delete (Should Fail)
    response = client.delete(
         f"/properties/{auth_headers['prop_id']}/documents/{doc_id}",
         headers={"Authorization": auth_headers["Authorization"]}
    )
    
    assert response.status_code == 403
    assert "VERIFIED" in response.json()["detail"]
    
    # Verify DB (Still exists)
    db = TestingSessionLocal()
    exists = db.query(PropertyDocument).filter_by(id=doc_id).first()
    assert exists is not None
    db.close()


