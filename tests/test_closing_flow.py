import pytest
from datetime import datetime
from backend.src.models.users import User, UserType
from backend.src.models.properties import Property
from backend.src.models.offers import PropertyOffer
from backend.src.models.enums import OfferStatus, PropertyStatus
from backend.src.models.timeline import TransactionStep, StepStatus, StepRole
from backend.src.services.closing_service import ClosingService
from backend.src.services.timeline_service import TimelineService
from fastapi import HTTPException

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
import backend.src.models # Ensure all models are registered

# --- SETUP ---
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_closing.db"
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
def test_property(db_session):
    # Need an owner first
    owner = User(
        email="owner_closing@test.com", 
        hashed_password="pw", 
        full_name="Owner Closing", 
        user_type=UserType.PARTICULAR
    )
    db_session.add(owner)
    db_session.commit()
    
    prop = Property(
        owner_id=owner.id, 
        title="Closing Prop", 
        price=250000, 
        description="Desc", 
        location="Madrid", 
        surface_area=100
    )
    db_session.add(prop)
    db_session.commit()
    return prop

@pytest.fixture
def test_user(db_session):
    # Aux user if needed
    user = User(
        email="aux_user@test.com", 
        hashed_password="pw", 
        full_name="Aux User", 
        user_type=UserType.PARTICULAR
    )
    db_session.add(user)
    db_session.commit()
    return user

@pytest.fixture
def closing_setup(db_session, test_property):
    # 1. Create Buyer
    buyer = User(
        email="buyer_closing@example.com",
        hashed_password="hash",
        full_name="Buyer Closing",
        user_type=UserType.PARTICULAR,
        email_verified=True
    )
    db_session.add(buyer)
    db_session.commit()
    
    # 2. Create Offer (SIGNED)
    offer = PropertyOffer(
        property_id=test_property.id,
        buyer_id=buyer.id,
        amount=250000,
        status=OfferStatus.SIGNED
    )
    db_session.add(offer)
    db_session.commit()
    
    # 3. Initialize Timeline
    TimelineService(db_session).initialize_timeline(offer)
    
    return offer, buyer

def test_closing_fails_if_timeline_incomplete(db_session, closing_setup):
    offer, _ = closing_setup
    
    # Verify timeline exists but is PENDING
    steps = db_session.query(TransactionStep).filter_by(offer_id=offer.id).all()
    assert len(steps) > 0
    assert steps[0].status == StepStatus.PENDING
    
    # Attempt Close
    with pytest.raises(HTTPException) as exc:
        ClosingService.execute_closing(db_session, offer.id)
    assert exc.value.status_code == 400
    assert "Pending steps" in exc.value.detail

def test_closing_success_flow(db_session, closing_setup):
    offer, _ = closing_setup
    
    # 1. Force Complete ALL steps
    steps = db_session.query(TransactionStep).filter_by(offer_id=offer.id).all()
    for step in steps:
        step.status = StepStatus.COMPLETED
        step.buyer_confirmed_at = datetime.utcnow()
        step.seller_confirmed_at = datetime.utcnow()
    db_session.commit()
    
    # 2. Execute Close
    closed_offer = ClosingService.execute_closing(db_session, offer.id)
    
    # 3. Assertions
    assert closed_offer.status == OfferStatus.COMPLETED
    
    # Property should be SOLD
    prop = db_session.query(Property).filter_by(id=offer.property_id).first()
    assert prop.status == PropertyStatus.SOLD
    
    # Audit msg
    print(f"Test Successful: Property {prop.id} is SOLD")
