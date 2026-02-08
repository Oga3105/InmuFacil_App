
import pytest
from datetime import datetime
from backend.src.models import User, Property, PropertyFeatures, PropertyValuation, ValuationProvider, ConservationState
from backend.src.services.valuation_service import ValuationService, ZONE_PRICES

# ============================================================================
# Test Database Setup
# ============================================================================
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_valuation.db"
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

def test_valuation_logic_basic(db_session):
    """
    Test basic valuation calculation without adjustments.
    """
    # Create User
    user = User(email="val@test.com", hashed_password="pw", full_name="Val User")
    db_session.add(user)
    db_session.commit()

    # Create Property
    prop = Property(
        title="Test Val",
        description="Desc",
        price=100000,
        location="Centro Madrid", # Should match "Centro" keyword
        surface_area=100,
        owner_id=user.id,
        created_at=datetime.utcnow()
    )
    db_session.add(prop)
    db_session.commit()
    
    # Calculate
    val = ValuationService.calculate_valuation(db_session, prop.id)
    
    # Assert
    expected_base = 100 * ZONE_PRICES["Centro"] # 100m2 * 3500
    assert val.estimated_value == expected_base
    assert val.provider == ValuationProvider.INTERNAL_ALGO


def test_valuation_logic_adjustments(db_session):
    """
    Test valuation with features (lift, terrace).
    """
    # Create User
    user = User(email="val2@test.com", hashed_password="pw", full_name="Val User 2")
    db_session.add(user)
    db_session.commit()

    prop = Property(
        title="Test Val Features",
        description="Desc",
        price=100000,
        location="Norte", # 4200
        surface_area=50,
        owner_id=user.id
    )
    db_session.add(prop)
    db_session.commit()
    
    # Add Features
    features = PropertyFeatures(
        property_id=prop.id,
        has_lift=True, # +10%
        has_terrace=True, # +5%
        conservation_state=ConservationState.BUEN_ESTADO # +0%
    )
    db_session.add(features)
    db_session.commit()
    
    # Calculate
    val = ValuationService.calculate_valuation(db_session, prop.id)
    
    base = 50 * 4200
    expected = base * 1.15 # 1.0 + 0.10 + 0.05
    
    # Use approximate comparison for floats/decimals
    assert abs(float(val.estimated_value) - expected) < 1.0


def test_valuation_history(db_session):
    """
    Test that valuations are saved in history.
    """
    # Create User
    user = User(email="val3@test.com", hashed_password="pw", full_name="Val User 3")
    db_session.add(user)
    db_session.commit()

    prop = Property(
        title="History Test", price=1, location="Sur", surface_area=10, owner_id=user.id
    )
    db_session.add(prop)
    db_session.commit()
    
    # Create 2 valuations
    v1 = ValuationService.calculate_valuation(db_session, prop.id)
    v2 = ValuationService.calculate_valuation(db_session, prop.id)
    
    history = ValuationService.get_valuation_history(db_session, prop.id)
    
    assert len(history) == 2
    # Should be ordered by date desc (newest first)
    assert history[0].id == v2.id
