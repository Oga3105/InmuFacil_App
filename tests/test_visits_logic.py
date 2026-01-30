"""
@Jules - Batch Visits Logic Tests (TDD)

Validated strict TDD requirements:
1. Window Creation
2. Slot Generation Algorithm (Critical)
3. Booking Logic
4. Overlap Prevention
"""

import pytest
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
from backend.src.models import User, Property, VisitWindow, VisitAppointment, VisitStatus
from backend.src.routes.visits import calculate_slots
from backend.src.schemas.base import VisitWindowCreate

# ============================================================================
# Test Database Setup
# ============================================================================

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_visits.db"
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
def mock_property(db_session):
    # Need a user first
    user = User(email="seller@test.com", hashed_password="pw", full_name="Seller")
    db_session.add(user)
    db_session.commit()
    
    prop = Property(
        title="Test House", price=100000, location="Madrid", 
        surface_area=100, owner_id=user.id
    )
    db_session.add(prop)
    db_session.commit()
    return prop

@pytest.fixture
def mock_buyer(db_session):
    user = User(email="buyer@test.com", hashed_password="pw", full_name="Buyer")
    db_session.add(user)
    db_session.commit()
    return user


# ============================================================================
# TDD Tests
# ============================================================================

def test_create_visit_window(db_session, mock_property):
    """
    Test 1: Seller can open availability.
    """
    start = datetime(2026, 5, 20, 10, 0)
    end = datetime(2026, 5, 20, 14, 0)
    
    window = VisitWindow(
        property_id=mock_property.id,
        start_time=start,
        end_time=end,
        slot_duration_minutes=20
    )
    db_session.add(window)
    db_session.commit()
    
    assert window.id is not None
    assert window.slot_duration_minutes == 20


def test_generate_slots_algorithm(db_session, mock_property):
    """
    Test 2 (CRITICAL): Calculate slots dynamically.
    Window: 10:00 - 11:00 (60 mins)
    Slot Duration: 20 mins
    Expected: 3 slots (10:00, 10:20, 10:40)
    """
    start = datetime(2026, 5, 20, 10, 0)
    end = datetime(2026, 5, 20, 11, 0)
    
    window = VisitWindow(
        property_id=mock_property.id,
        start_time=start,
        end_time=end,
        slot_duration_minutes=20
    )
    db_session.add(window)
    db_session.commit()
    
    # Logic unit test (no existing appointments)
    slots = calculate_slots(window, [])
    
    assert len(slots) == 3
    assert slots[0].start_time == datetime(2026, 5, 20, 10, 0)
    assert slots[1].start_time == datetime(2026, 5, 20, 10, 20)
    assert slots[2].start_time == datetime(2026, 5, 20, 10, 40)
    assert all(s.is_available for s in slots)


def test_book_slot_reduces_availability(db_session, mock_property, mock_buyer):
    """
    Test 3: Booked slot shows as unavailable.
    """
    start = datetime(2026, 5, 20, 10, 0)
    end = datetime(2026, 5, 20, 10, 40) # 2 slots (10:00, 10:20)
    
    window = VisitWindow(
        property_id=mock_property.id,
        start_time=start,
        end_time=end,
        slot_duration_minutes=20
    )
    db_session.add(window)
    db_session.commit()
    
    # Buyer books 10:00
    appt = VisitAppointment(
        window_id=window.id,
        buyer_id=mock_buyer.id,
        start_time=datetime(2026, 5, 20, 10, 0),
        status=VisitStatus.REQUESTED
    )
    db_session.add(appt)
    db_session.commit()
    
    # Recalculate slots
    slots = calculate_slots(window, [appt])
    
    assert len(slots) == 2
    # 10:00 should be unavailable
    assert slots[0].start_time == datetime(2026, 5, 20, 10, 0)
    assert slots[0].is_available == False
    
    # 10:20 should be available
    assert slots[1].start_time == datetime(2026, 5, 20, 10, 20)
    assert slots[1].is_available == True


def test_prevent_overlap(db_session, mock_property):
    """
    Test 4: Seller cannot create overlapping windows.
    """
    # Create first window: 10:00 - 12:00
    w1 = VisitWindow(
        property_id=mock_property.id,
        start_time=datetime(2026, 5, 20, 10, 0),
        end_time=datetime(2026, 5, 20, 12, 0)
    )
    db_session.add(w1)
    db_session.commit()
    
    # Try to create overlapping: 11:00 - 13:00
    # Ideally this logic is in the Service/Router layer, checking manually here for logic
    # In router we use:
    # overlap = db.query(VisitWindow).filter(...)
    
    new_start = datetime(2026, 5, 20, 11, 0)
    new_end = datetime(2026, 5, 20, 13, 0)
    
    from sqlalchemy import and_
    overlap = db_session.query(VisitWindow).filter(
        VisitWindow.property_id == mock_property.id,
        and_(
            VisitWindow.start_time < new_end,
            VisitWindow.end_time > new_start
        )
    ).first()
    
    assert overlap is not None
    assert overlap.id == w1.id

def test_booking_with_filtering_questions(db_session, mock_property, mock_buyer):
    """
    Test 5: Explicitly verify storage of Hito 10 filtering questions.
    """
    # Create Window
    w = VisitWindow(
        property_id=mock_property.id,
        start_time=datetime(2026, 6, 1, 10, 0),
        end_time=datetime(2026, 6, 1, 12, 0)
    )
    db_session.add(w)
    db_session.commit()
    
    # Book with Questions
    appt = VisitAppointment(
        window_id=w.id,
        buyer_id=mock_buyer.id,
        start_time=datetime(2026, 6, 1, 10, 0),
        status=VisitStatus.REQUESTED,
        q_solvency="Contado",
        q_timeline="Inmediato",
        q_maturity="Primera visita"
    )
    db_session.add(appt)
    db_session.commit()
    db_session.refresh(appt)
    
    assert appt.q_solvency == "Contado"
    assert appt.q_timeline == "Inmediato"
    assert appt.q_maturity == "Primera visita"
