import pytest
from datetime import datetime
from backend.src.models.timeline import TransactionStep, StepStatus, StepRole
from backend.src.services.timeline_service import TimelineService
from backend.src.models.users import User, UserType
from backend.src.models.properties import Property
from backend.src.models.offers import PropertyOffer, OfferStatus
from backend.src.models.notaries import Notary 
# Import Timeline explicitly just in case (already imported, but ensuring order)
from backend.src.models.timeline import TransactionStep
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base

# --- SETUP ---
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_timeline.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db_session():
    # Helper to ensure Base knows about all models
    # Import them here or ensure top-level imports are sufficient
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        # Drop to ensure clean state
        Base.metadata.drop_all(bind=engine)

# --- FIXTURES ---

@pytest.fixture
def timeline_service(db_session):
    return TimelineService(db_session)

@pytest.fixture
def setup_accepted_offer(db_session):
    # Create Users
    seller = User(email="seller_time@test.com", hashed_password="pw", full_name="Seller Time", user_type=UserType.PARTICULAR)
    buyer = User(email="buyer_time@test.com", hashed_password="pw", full_name="Buyer Time", user_type=UserType.PARTICULAR)
    db_session.add_all([seller, buyer])
    db_session.commit()
    
    # Create Property
    prop = Property(owner_id=seller.id, title="Timeline Prop", price=100000, description="Desc", location="Madrid", surface_area=100)
    db_session.add(prop)
    db_session.commit()
    
    # Create Offer
    offer = PropertyOffer(
        property_id=prop.id,
        buyer_id=buyer.id,
        amount=95000,
        status=OfferStatus.ACCEPTED # Accepted!
    )
    db_session.add(offer)
    db_session.commit()
    
    return offer, seller, buyer

# --- TESTS ---

def test_initialization_creates_steps(timeline_service, setup_accepted_offer, db_session):
    offer, _, _ = setup_accepted_offer
    
    steps = timeline_service.initialize_timeline(offer)
    
    assert len(steps) == 7
    assert steps[0].step_key == "CONTRACT_GENERATION"
    assert steps[2].step_key == "ARRAS_PAYMENT"
    assert steps[2].required_role == StepRole.BOTH
    assert steps[2].status == StepStatus.PENDING

def test_dual_confirmation_flow(timeline_service, setup_accepted_offer, db_session):
    offer, _, _ = setup_accepted_offer
    steps = timeline_service.initialize_timeline(offer)
    
    # Get Arras Payment Step (Index 2, Order 3)
    arras_step = steps[2] 
    step_id = arras_step.id
    
    # 1. Buyer Confirms
    updated_step = timeline_service.confirm_step(step_id, "BUYER", {"note": "Sent"})
    
    assert updated_step.status == StepStatus.PARTIALLY_COMPLETED
    assert updated_step.buyer_confirmed_at is not None
    assert updated_step.seller_confirmed_at is None
    
    # 2. Seller Confirms
    updated_step_2 = timeline_service.confirm_step(step_id, "SELLER", {"note": "Received"})
    
    assert updated_step_2.status == StepStatus.COMPLETED
    assert updated_step_2.seller_confirmed_at is not None

def test_single_role_confirmation(timeline_service, setup_accepted_offer, db_session):
    offer, _, _ = setup_accepted_offer
    steps = timeline_service.initialize_timeline(offer)
    
    # Mortgage Approval (Index 4, Order 5) - Buyer Only
    mortgage_step = steps[4]
    
    timeline_service.confirm_step(mortgage_step.id, "BUYER", {"note": "Got it"})
    
    db_session.refresh(mortgage_step)
    assert mortgage_step.status == StepStatus.COMPLETED

def test_wrong_role_confirmation_rejected(timeline_service, setup_accepted_offer, db_session):
    offer, _, _ = setup_accepted_offer
    steps = timeline_service.initialize_timeline(offer)
    
    # Mortgage (Buyer Only)
    mortgage_step = steps[4]
    
    with pytest.raises(PermissionError):
        timeline_service.confirm_step(mortgage_step.id, "SELLER", {})
