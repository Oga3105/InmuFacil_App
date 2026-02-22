
import pytest
from decimal import Decimal
from backend.src.models.financing import MortgageProfile, MortgageSimulation, EmploymentStatus
from backend.src.services.financing_service import FinancingService
from backend.src.models import User, UserType
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base

# ============================================================================
# DB Setup
# ============================================================================
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_financing.db"
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

# ============================================================================
# Tests
# ============================================================================

def test_solvency_score_calculation(db_session):
    """
    Test the internal scoring logic.
    """
    # 1. High Profile (Funcionario + High Income)
    p1 = MortgageProfile(
        monthly_net_income=3500,
        monthly_debts=0,
        savings_available=50000,
        employment_status=EmploymentStatus.FUNCIONARIO,
        contract_years=10,
        age=40
    )
    score1 = FinancingService.calculate_solvency_score(p1)
    
    # Base 50 + Funcionario (30) + High Income (10) = 90
    assert score1 >= 90
    
    # 2. Low Profile (Temporal + Low Income)
    p2 = MortgageProfile(
        monthly_net_income=1000,
        monthly_debts=0,
        savings_available=0,
        employment_status=EmploymentStatus.TEMPORAL,
        contract_years=0,
        age=25
    )
    score2 = FinancingService.calculate_solvency_score(p2)
    # Base 50 + Temporal (0) - Low Income (10) = 40
    assert score2 <= 40

def test_simulation_generation(db_session):
    """
    Test creating a simulation and fetching mock offers.
    """
    # Setup User & Profile
    user = User(email="mortgage@test.com", hashed_password="pw", full_name="Mortgage User")
    db_session.add(user)
    db_session.commit()
    
    profile = MortgageProfile(
        user_id=user.id,
        monthly_net_income=3500,
        monthly_debts=500,
        savings_available=40000,
        employment_status=EmploymentStatus.INDEFINIDO,
        contract_years=5,
        age=35
    )
    db_session.add(profile)
    db_session.commit()
    
    # Run Simulation
    sim = FinancingService.simulate_mortgage(db_session, user.id, amount=200000)
    
    assert sim.id is not None
    assert sim.solvency_score > 50
    assert sim.is_viable_internal is True
    assert "Banco Santander" in sim.offers_snapshot
    assert "iAhorro" in sim.offers_snapshot

def test_financial_advisor_assignment(db_session):
    """
    Test assigning a 'Financiero' to a user.
    """
    # 1. Create Advisor
    advisor = User(
        email="broker@test.com", 
        hashed_password="pw", 
        full_name="The Broker",
        user_type=UserType.FINANCIERO
    )
    db_session.add(advisor)
    
    # 2. Create Client
    client = User(
        email="client@test.com",
        hashed_password="pw",
        full_name="Client"
    )
    db_session.add(client)
    db_session.commit()
    
    # 3. Assign
    client.financial_advisor_id = advisor.id
    db_session.commit()
    db_session.refresh(client)
    
    assert client.financial_advisor.email == "broker@test.com"
    assert len(advisor.advisees) == 1
