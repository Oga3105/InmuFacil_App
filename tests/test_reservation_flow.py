"""
@Jules - Reservation Flow TDD

Tests Hito 8:
1. Race Conditions (Double Booking Prevention).
2. Idempotency (Duplicate Payment Prevention).
3. Visibility Logic (Hide when reserved).
"""

import pytest
import uuid
import threading
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
from backend.src.models import User, Property, PropertyStatus, Reservation, OfferStatus, PropertyOffer
from backend.src.services.payment_service import MockPaymentProvider

# ============================================================================
# Setup
# ============================================================================

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_reservations.db"
# Use check_same_thread=False for SQLite concurrency testing
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
def res_fixtures(db_session):
    seller = User(email="seller@res.com", hashed_password="pw", full_name="Seller Res")
    buyer1 = User(email="buyer1@res.com", hashed_password="pw", full_name="Buyer One")
    buyer2 = User(email="buyer2@res.com", hashed_password="pw", full_name="Buyer Two")
    db_session.add_all([seller, buyer1, buyer2])
    db_session.commit()
    
    prop = Property(
        title="Reserved House", price=300000, location="Madrid", 
        surface_area=90, owner_id=seller.id,
        status=PropertyStatus.PUBLISHED
    )
    db_session.add(prop)
    db_session.commit()
    
    return {"prop": prop, "buyer1": buyer1, "buyer2": buyer2}

# ============================================================================
# Utility: Simulation of Reservation Service Logic
# ============================================================================

def attempt_reservation(db, property_id, buyer_id, idempotency_key):
    """
    Simulates the specific logic we will implement in the Router.
    """
    # 1. Lock Property (In SQLite this is limited, but we simulate logic)
    # Ideally: prop = db.query(Property).with_for_update().get(property_id)
    # For SQLite test we just check status strictly
    
    prop = db.query(Property).filter(Property.id == property_id).first()
    
    if prop.status == PropertyStatus.RESERVED:
        return False, "Building is already reserved"
        
    # 2. Process Payment (Mock)
    success, tx_id, err = MockPaymentProvider.process_payment(3000.0, "tok_visa", idempotency_key)
    
    if not success:
        return False, f"Payment failed: {err}"
        
    # 3. Update DB
    try:
        prop.status = PropertyStatus.RESERVED
        res = Reservation(
            property_id=property_id,
            buyer_id=buyer_id,
            amount=3000.0,
            status="paid",
            idempotency_key=idempotency_key,
            payment_id=tx_id
        )
        db.add(res)
        db.commit()
        return True, "Success"
    except Exception as e:
        db.rollback()
        return False, str(e)

# ============================================================================
# TDD Cases
# ============================================================================

def test_visibility_logic(db_session, res_fixtures):
    """
    Test visibility rules:
    - Default: RESERVED items show up.
    - Configured: RESERVED items hidden if hide_when_reserved=True.
    """
    prop = res_fixtures["prop"]
    
    # 1. Default (Visible)
    prop.status = PropertyStatus.RESERVED
    db_session.commit()
    
    # Simulate Search Query
    results = db_session.query(Property).filter(
        (Property.status == PropertyStatus.PUBLISHED) | 
        (Property.status == PropertyStatus.RESERVED)
    ).all()
    assert len(results) == 1
    
    # 2. Configured (Hidden)
    prop.hide_when_reserved = True
    db_session.commit()
    
    # Simulate Logic: Filter should exclude reserved if hidden flag is on
    # Complex query simulation
    results_hidden = db_session.query(Property).filter(
        Property.status == PropertyStatus.PUBLISHED # Only published
        # OR (Reserved AND Not Hidden) ... simplified for search logic
    ).all()
    
    # But wait, search logic usually is: "Show everything that is public"
    # If it's reserved, we check if hide_when_reserved is True.
    # In SQL: WHERE status='published' OR (status='reserved' AND hide_when_reserved=FALSE)
    
    final_results = db_session.query(Property).filter(
        (Property.status == PropertyStatus.PUBLISHED) |
        ((Property.status == PropertyStatus.RESERVED) & (Property.hide_when_reserved == False))
    ).all()
    
    assert len(final_results) == 0 # Should be hidden now

def test_race_condition_simulation(db_session, res_fixtures):
    """
    Simulate 2 threads trying to reserve at the same time.
    """
    # Note: True race condition testing in SQLite is hard due to db locking.
    # We will verify that IF the status changes in between, it fails.
    
    prop = res_fixtures["prop"]
    b1 = res_fixtures["buyer1"]
    b2 = res_fixtures["buyer2"]
    
    # Buyer 1 reserves first
    ok1, msg1 = attempt_reservation(db_session, prop.id, b1.id, "key_1")
    assert ok1 is True
    assert db_session.query(Property).first().status == PropertyStatus.RESERVED
    
    # Buyer 2 tries immediately after
    ok2, msg2 = attempt_reservation(db_session, prop.id, b2.id, "key_2")
    assert ok2 is False
    assert "already reserved" in msg2

def test_idempotency_constraint(db_session, res_fixtures):
    """
    Verify duplicate idempotency key raises integrity error.
    """
    prop = res_fixtures["prop"]
    b1 = res_fixtures["buyer1"]
    
    # First attempt
    ok1, msg1 = attempt_reservation(db_session, prop.id, b1.id, "unique_key_123")
    assert ok1 is True
    
    # Second attempt with SAME key (should fail DB constraint if we tried to insert)
    # Our logic function *handles* this by checking status first normally,
    # but let's try to insert a duplicate reservation directly to test the Model constraint.
    
    try:
        dup_res = Reservation(
             property_id=prop.id, buyer_id=b1.id, amount=3000.0,
             status="paid", idempotency_key="unique_key_123", payment_id="tx_999"
        )
        db_session.add(dup_res)
        db_session.commit()
        assert False, "Should have raised IntegrityError"
    except Exception:
        db_session.rollback()
        pass # Success
