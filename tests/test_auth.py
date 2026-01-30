"""
@Jules - Authentication Tests (TDD)

Test suite for user authentication and registration.
Validates user creation, password hashing, and model integrity.

Token Consumption Tracking: ~600 tokens for test implementation
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.src.models.base import Base
from backend.src.models import User, DNIStatus, UserType
from backend.src.utils.security import hash_password, verify_password


# ============================================================================
# Test Database Setup
# ============================================================================

# Create in-memory SQLite database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db_session():
    """
    Create a fresh database session for each test.
    Ensures test isolation and cleanup.
    """
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


# ============================================================================
# User Model Tests
# ============================================================================

def test_create_user_successfully(db_session):
    """
    Test: User can be created with valid data
    
    @Jules: Validates basic user creation functionality
    """
    # Arrange
    user_data = {
        "email": "test@inmufacil.com",
        "hashed_password": hash_password("SecurePassword123!"),
        "full_name": "Juan Pérez García",
        "dni_status": DNIStatus.PENDIENTE,
        "user_type": UserType.PARTICULAR
    }
    
    # Act
    user = User(**user_data)
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    # Assert
    assert user.id is not None
    assert user.email == "test@inmufacil.com"
    assert user.full_name == "Juan Pérez García"
    assert user.dni_status == DNIStatus.PENDIENTE
    assert user.user_type == UserType.PARTICULAR
    assert user.created_at is not None


def test_user_email_must_be_unique(db_session):
    """
    Test: Email uniqueness constraint is enforced
    
    @Jules: Validates database constraints
    """
    # Arrange
    email = "duplicate@inmufacil.com"
    user1 = User(
        email=email,
        hashed_password=hash_password("Password1!"),
        full_name="User One",
    )
    user2 = User(
        email=email,
        hashed_password=hash_password("Password2!"),
        full_name="User Two",
    )
    
    # Act & Assert
    db_session.add(user1)
    db_session.commit()
    
    db_session.add(user2)
    with pytest.raises(Exception):  # SQLAlchemy will raise IntegrityError
        db_session.commit()


def test_password_is_hashed_not_plain_text(db_session):
    """
    Test: Password is stored as hash, not plain text
    
    @Shield: Validates password security
    """
    # Arrange
    plain_password = "MySecretPassword123!"
    hashed = hash_password(plain_password)
    
    user = User(
        email="secure@inmufacil.com",
        hashed_password=hashed,
        full_name="Secure User",
    )
    
    # Act
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    # Assert
    assert user.hashed_password != plain_password
    assert user.hashed_password.startswith("$2b$")  # Bcrypt hash prefix
    assert verify_password(plain_password, user.hashed_password)


def test_user_defaults_are_applied(db_session):
    """
    Test: Default values for dni_status and user_type are applied
    
    @Jules: Validates model defaults
    """
    # Arrange & Act
    user = User(
        email="defaults@inmufacil.com",
        hashed_password=hash_password("Password123!"),
        full_name="Default User",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    # Assert
    assert user.dni_status == DNIStatus.PENDIENTE
    assert user.user_type == UserType.PARTICULAR


def test_user_type_can_be_profesional(db_session):
    """
    Test: User can be created as 'profesional' type
    
    @Jules: Validates user type enumeration
    """
    # Arrange & Act
    user = User(
        email="pro@inmufacil.com",
        hashed_password=hash_password("ProPassword123!"),
        full_name="Professional User",
        user_type=UserType.PROFESIONAL
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    # Assert
    assert user.user_type == UserType.PROFESIONAL


# ============================================================================
# Security Tests
# ============================================================================

def test_password_hashing_is_consistent():
    """
    Test: Same password produces different hashes (due to salt)
    
    @Shield: Validates Bcrypt salting
    """
    password = "TestPassword123!"
    hash1 = hash_password(password)
    hash2 = hash_password(password)
    
    # Different hashes due to unique salts
    assert hash1 != hash2
    
    # But both verify correctly
    assert verify_password(password, hash1)
    assert verify_password(password, hash2)


def test_password_verification_fails_for_wrong_password():
    """
    Test: Password verification fails for incorrect password
    
    @Shield: Validates password verification security
    """
    correct_password = "CorrectPassword123!"
    wrong_password = "WrongPassword456!"
    
    hashed = hash_password(correct_password)
    
    assert verify_password(correct_password, hashed)
    assert not verify_password(wrong_password, hashed)
