"""
@Jules - Advanced Search Logic TDD

Tests dynamic filtering capabilities:
1. Core Filters: Price Range, Location (Partial Match), Type.
2. Satellite Filters: Features (Has Pool, Headers).
3. Combinations: "Piso in Madrid with Pool < 300k".
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
from backend.src.models import Property, PropertyFeatures, PropertyType, PropertyStatus, User

# ============================================================================
# Setup
# ============================================================================

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_search.db"
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
def search_fixtures(db_session):
    owner = User(email="owner@search.com", hashed_password="pw", full_name="Owner")
    db_session.add(owner)
    db_session.commit()
    
    # Prop 1: Cheap Flat in Madrid with Pool
    p1 = Property(
        title="Apartamento Centro", price=150000, location="Madrid Centro",
        surface_area=50, property_type=PropertyType.PISO, owner_id=owner.id,
        status=PropertyStatus.PUBLISHED
    )
    db_session.add(p1)
    db_session.flush()
    f1 = PropertyFeatures(property_id=p1.id, has_pool=True, has_terrace=False)
    db_session.add(f1)
    
    # Prop 2: Expensive House in Madrid (No Pool)
    p2 = Property(
        title="Chalet de Lujo", price=500000, location="Madrid Norte",
        surface_area=200, property_type=PropertyType.CHALET, owner_id=owner.id,
        status=PropertyStatus.PUBLISHED
    )
    db_session.add(p2)
    db_session.flush()
    # No features defined (should handle missing satellite gracefully)
    
    # Prop 3: Cheap Flat in Barcelona (Has Pool)
    p3 = Property(
        title="Piso Playa", price=180000, location="Barcelona",
        surface_area=60, property_type=PropertyType.PISO, owner_id=owner.id,
        status=PropertyStatus.PUBLISHED
    )
    db_session.add(p3)
    db_session.flush()
    f3 = PropertyFeatures(property_id=p3.id, has_pool=True, has_terrace=True)
    db_session.add(f3)

    # Prop 4: Reserved (should be visible by default)
    p4 = Property(
        title="Reserved Flat", price=100000, location="Madrid",
        surface_area=50, property_type=PropertyType.PISO, owner_id=owner.id,
        status=PropertyStatus.RESERVED
    )
    db_session.add(p4)

    db_session.commit()
    return [p1, p2, p3, p4]

# ============================================================================
# TDD Cases (Simulating Router Logic)
# ============================================================================

def filter_properties(db, min_price=None, max_price=None, location=None, 
                      p_type=None, has_pool=None):
    """
    Simulates the dynamic query builder we will implement in the router.
    """
    # Start with Base Query (Joining Features for filtering)
    query = db.query(Property).outerjoin(PropertyFeatures)
    
    # Core Filters
    if min_price is not None:
        query = query.filter(Property.price >= min_price)
    if max_price is not None:
        query = query.filter(Property.price <= max_price)
    if location:
        # Case insensitive partial match
        query = query.filter(Property.location.ilike(f"%{location}%"))
    if p_type:
        query = query.filter(Property.property_type == p_type)
        
    # Satellite Filters (Features)
    if has_pool is not None:
        if has_pool:
            query = query.filter(PropertyFeatures.has_pool == True)
        else:
            # Careful: Needs to handle NULL if left joined? 
            # Usually "Not has pool" means has_pool=False OR has_pool IS NULL
            from sqlalchemy import or_
            query = query.filter(or_(PropertyFeatures.has_pool == False, PropertyFeatures.has_pool == None))
            
    return query.all()

def test_filter_price_range(db_session, search_fixtures):
    # 150k to 200k
    results = filter_properties(db_session, min_price=150000, max_price=200000)
    assert len(results) == 2 # p1, p3
    assert all(150000 <= p.price <= 200000 for p in results)

def test_filter_location(db_session, search_fixtures):
    results = filter_properties(db_session, location="Madrid")
    assert len(results) == 3 # p1, p2, p4
    
def test_filter_type_and_feature(db_session, search_fixtures):
    # Flats with Pool
    results = filter_properties(db_session, p_type=PropertyType.PISO, has_pool=True)
    assert len(results) == 2 # p1 (Madrid), p3 (Barcelona)
    # p4 is "Reserved" but has no features defined -> pool is False/Null -> Excluded?
    # Wait, p4 features null. If we want "Has Pool", Null doesn't count. Correct.

def test_combinatorial_search(db_session, search_fixtures):
    # "Piso in Madrid < 200k"
    results = filter_properties(
        db_session, 
        location="Madrid", 
        p_type=PropertyType.PISO, 
        max_price=200000
    )
    # Candidates:
    # p1: Madrid, Piso, 150k -> Match
    # p2: Madrid, Chalet, 500k -> Fail type & price
    # p3: Barcelona, Piso, 180k -> Fail location
    # p4: Madrid, Piso, 100k -> Match
    
    assert len(results) == 2
    ids = [p.id for p in results]
    assert search_fixtures[0].id in ids
    assert search_fixtures[3].id in ids
