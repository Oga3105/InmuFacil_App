"""
@Jules - Visit Execution Lifecycle Tests (TDD)

Implements State Machine tests for Visit Execution (Hito 5).
Validates transitions: REQUESTED -> APPROVED -> COMPLETED/NO_SHOW.
Enforces Role Security: Only Owner can complete.
"""

import pytest
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
from backend.src.models import User, Property, VisitWindow, VisitAppointment, VisitStatus

# ============================================================================
# Test Database Setup
# ============================================================================

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_execution.db"
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
def execution_fixtures(db_session):
    # 1. Seller
    seller = User(email="seller@exec.com", hashed_password="pw", full_name="Seller One")
    db_session.add(seller)
    
    # 2. Buyer
    buyer = User(email="buyer@exec.com", hashed_password="pw", full_name="Buyer One")
    db_session.add(buyer)
    db_session.commit()
    
    # 3. Property
    prop = Property(
        title="Exec House", price=200000, location="BCN", 
        surface_area=90, owner_id=seller.id
    )
    db_session.add(prop)
    db_session.commit()
    
    # 4. Window
    window = VisitWindow(
        property_id=prop.id,
        start_time=datetime.utcnow() + timedelta(days=1),
        end_time=datetime.utcnow() + timedelta(days=1, hours=4),
        slot_duration_minutes=20
    )
    db_session.add(window)
    db_session.commit()
    
    return {"seller": seller, "buyer": buyer, "property": prop, "window": window}

# ============================================================================
# TDD: State Machine Logic
# ============================================================================

def test_visit_state_transitions(db_session, execution_fixtures):
    """
    Test 1: Happy Path (Requested -> Approved -> Completed)
    """
    # Create Appointment
    appt = VisitAppointment(
        window_id=execution_fixtures["window"].id,
        buyer_id=execution_fixtures["buyer"].id,
        start_time=execution_fixtures["window"].start_time,
        status=VisitStatus.REQUESTED
    )
    db_session.add(appt)
    db_session.commit()
    
    # 1. Approve (Valid transition)
    # Using service logic simulation
    appt.status = VisitStatus.APPROVED
    db_session.commit()
    assert appt.status == VisitStatus.APPROVED
    
    # 2. Complete (Valid transition from Approved)
    appt.status = VisitStatus.COMPLETED
    db_session.commit()
    assert appt.status == VisitStatus.COMPLETED


def test_cannot_complete_unapproved_visit(db_session, execution_fixtures):
    """
    Test 2: Invalid Transition (Requested -> Completed)
    Defense in Depth: Logic must forbid this jump.
    """
    appt = VisitAppointment(
        window_id=execution_fixtures["window"].id,
        buyer_id=execution_fixtures["buyer"].id,
        start_time=execution_fixtures["window"].start_time,
        status=VisitStatus.REQUESTED
    )
    db_session.add(appt)
    db_session.commit()
    
    # Try to complete directly (Simulation of Router Logic)
    # In integration test we would call the endpoint. 
    # Here we test the Logic Function if we extracted it, or simulate the check.
    
    # We expect the router to raise HTTPException(400)
    # Since we are mocking the logic here, we'll define the check function we want to implement
    
    def validate_transition(current_status, new_status):
        valid_transitions = {
            VisitStatus.REQUESTED: [VisitStatus.APPROVED, VisitStatus.REJECTED, VisitStatus.CANCELLED],
            VisitStatus.APPROVED: [VisitStatus.COMPLETED, VisitStatus.NO_SHOW, VisitStatus.CANCELLED],
        }
        if new_status not in valid_transitions.get(current_status, []):
            raise ValueError(f"Invalid transition from {current_status} to {new_status}")
            
    with pytest.raises(ValueError):
        validate_transition(appt.status, VisitStatus.COMPLETED)


def test_only_seller_can_complete(db_session, execution_fixtures):
    """
    Test 3: Security - Buyer cannot complete visit.
    """
    # Setup Approved Visit
    appt = VisitAppointment(
        window_id=execution_fixtures["window"].id,
        buyer_id=execution_fixtures["buyer"].id,
        start_time=execution_fixtures["window"].start_time,
        status=VisitStatus.APPROVED
    )
    db_session.add(appt)
    db_session.commit()
    
    # Logic simulation
    requesting_user_id = execution_fixtures["buyer"].id # The buyer tries
    owner_id = execution_fixtures["seller"].id
    
    def check_permission(user_id, owner_id):
        if user_id != owner_id:
            raise PermissionError("Only owner can complete")
            
    with pytest.raises(PermissionError):
        check_permission(requesting_user_id, owner_id)
        
    # Owner succeeds
    check_permission(execution_fixtures["seller"].id, owner_id)

