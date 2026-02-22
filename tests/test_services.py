import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.main import app
from backend.src.config.database import get_db
from backend.src.models.base import Base
from backend.src.models import User, UserType
from backend.src.models.services import ServiceOrder

from backend.src.utils.security import create_access_token
from backend.src.models.enums import ServiceType, ServiceStatus

# --- SETUP ---
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_services.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

@pytest.fixture(scope="module")
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def db_session(setup_db):
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

@pytest.fixture
def service_client(db_session):
    # Setup Users
    requester = User(email="req@s.com", full_name="Requester", hashed_password="x", user_type=UserType.PARTICULAR)
    provider = User(email="prov@s.com", full_name="Provider", hashed_password="x", user_type=UserType.PROVIDER, provider_category="VALUER")
    admin = User(email="admin@inmufacil.com", full_name="Admin", hashed_password="x", user_type="admin") # Hardcoded check in router uses string comparison often
    # Note: UserType.ADMIN is "admin" enum
    
    db_session.add_all([requester, provider, admin])
    db_session.commit()
    
    return {
        "req": create_access_token({"sub": requester.email}),
        "prov": create_access_token({"sub": provider.email}),
        "admin": create_access_token({"sub": admin.email}),
        "req_id": requester.id,
        "prov_id": provider.id
    }

def test_service_lifecycle(service_client, db_session):
    tokens = service_client
    
    # 1. Requester creates order
    response = client.post(
        "/services/request",
        json={"service_type": "valuation", "requester_notes": "Need fast valuation"},
        headers={"Authorization": f"Bearer {tokens['req']}"}
    )
    assert response.status_code == 201
    data = response.json()
    order_id = data["id"]
    assert data["status"] == "requested"
    assert "VAL-" in data["ticket_number"]
    
    # 2. Provider checks list -> Should see empty (Not assigned)
    response = client.get(
        "/services/",
        headers={"Authorization": f"Bearer {tokens['prov']}"}
    )
    assert response.status_code == 200
    assert len(response.json()) == 0

    # 3. Admin assigns provider (Manual DB injection for MVP router limits)
    # Ideally Admin PATCH, but let's do DB to be fast
    order = db_session.query(ServiceOrder).get(order_id)
    order.provider_id = tokens["prov_id"]
    order.status = ServiceStatus.ASSIGNED
    db_session.commit()
    
    # 4. Provider sees order now
    response = client.get(
        "/services/",
        headers={"Authorization": f"Bearer {tokens['prov']}"}
    )
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["id"] == order_id
    
    # 5. Provider updates result
    response = client.patch(
        f"/services/{order_id}",
        json={"status": "completed", "final_price": 350.0, "result_data": {"value": 500000}},
        headers={"Authorization": f"Bearer {tokens['prov']}"}
    )
    assert response.status_code == 200
    assert response.json()["status"] == "completed"
    
    # 6. Requester Rates
    response = client.patch(
        f"/services/{order_id}",
        json={"rating": 5},
        headers={"Authorization": f"Bearer {tokens['req']}"}
    )
    assert response.status_code == 200
    assert response.json()["rating"] == 5
