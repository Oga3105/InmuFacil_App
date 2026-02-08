import pytest
from unittest.mock import AsyncMock, patch
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
from backend.src.models.users import User, UserType
from backend.src.models.properties import Property
from backend.src.models.offers import PropertyOffer, OfferStatus
from backend.src.models.handover import PropertyHandover
from backend.src.services.handover_service import HandoverService
from fastapi import HTTPException, UploadFile
import backend.src.models # Register all models

# --- SETUP ---
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_handover.db"
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
def keys_setup(db_session):
    # 1. Owner
    owner = User(email="owner@h.com", hashed_password="pw", full_name="Owner H", user_type=UserType.PARTICULAR)
    db_session.add(owner)
    
    # 2. Buyer
    buyer = User(email="buyer@h.com", hashed_password="pw", full_name="Buyer H", user_type=UserType.PARTICULAR)
    db_session.add(buyer)
    
    # 3. Random
    random = User(email="random@h.com", hashed_password="pw", full_name="Stranger", user_type=UserType.PARTICULAR)
    db_session.add(random)
    
    db_session.commit()
    
    # 4. Property
    prop = Property(owner_id=owner.id, title="Handover Prop", price=100, description="D", location="L", surface_area=1)
    db_session.add(prop)
    db_session.commit()
    
    # 5. Offer (COMPLETED)
    offer = PropertyOffer(property_id=prop.id, buyer_id=buyer.id, amount=100, status=OfferStatus.COMPLETED)
    db_session.add(offer)
    db_session.commit()
    
    return owner, buyer, random, offer

def test_upsert_handover_data(db_session, keys_setup):
    owner, buyer, random, offer = keys_setup
    
    data = {
        "electricity_cups": "ES002100000",
        "gas_cups": "ES002200000",
        "community_fee_monthly": 50.0
    }
    
    # 1. Seller Updates -> Success
    handover = HandoverService.upsert_handover_data(db_session, offer.id, owner, data)
    assert handover.electricity_cups == "ES002100000"
    assert handover.offer_id == offer.id
    
    # 2. Random Updates -> Fail
    with pytest.raises(HTTPException) as exc:
        HandoverService.upsert_handover_data(db_session, offer.id, random, data)
    assert exc.value.status_code == 403
    
    # 3. Buyer Updates -> Fail (Only Seller prepares handover)
    with pytest.raises(HTTPException) as exc:
        HandoverService.upsert_handover_data(db_session, offer.id, buyer, data)
    assert exc.value.status_code == 403

def test_get_handover_acl(db_session, keys_setup):
    owner, buyer, random, offer = keys_setup
    
    # Init data
    HandoverService.upsert_handover_data(db_session, offer.id, owner, {"water_reference": "W123"})
    
    # 1. Buyer reads -> Success
    h_buyer = HandoverService.get_handover(db_session, offer.id, buyer)
    assert h_buyer.water_reference == "W123"
    
    # 2. Seller reads -> Success
    h_seller = HandoverService.get_handover(db_session, offer.id, owner)
    assert h_seller.id == h_buyer.id
    
    # 3. Random reads -> Fail
    with pytest.raises(HTTPException) as exc:
        HandoverService.get_handover(db_session, offer.id, random)
    assert exc.value.status_code == 403

@pytest.mark.anyio
async def test_upload_bill_mocked(db_session, keys_setup):
    owner, buyer, random, offer = keys_setup
    
    # Mock File
    mock_file = AsyncMock(spec=UploadFile)
    mock_file.filename = "factura.pdf"
    
    # Mock DocumentService to avoid real encryption
    with patch("backend.src.services.handover_service.DocumentService.save_protected_document") as mock_save:
        mock_save.return_value = "uploads/protected/factura_encrypted.enc"
        
        # Action
        handover = await HandoverService.upload_bill(db_session, offer.id, owner, "electricity", mock_file)
        
        # Verify
        assert handover.bill_electricity_path == "uploads/protected/factura_encrypted.enc"
        mock_save.assert_called_once()
        
    # Verify DB Persistence
    db_session.refresh(handover)
    assert handover.bill_electricity_path is not None
