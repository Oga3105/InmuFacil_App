from sqlalchemy import Column, Integer, String, Text, DateTime, UniqueConstraint
from sqlalchemy.sql import func
from .base import Base


class AiComfortIndexCache(Base):
    __tablename__ = "ai_comfort_index_cache"
    __table_args__ = (UniqueConstraint("property_id", name="uq_comfort_property"),)

    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(String(50), nullable=False, index=True)
    response_json = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class AiLegalGuideCache(Base):
    __tablename__ = "ai_legal_guide_cache"
    __table_args__ = (UniqueConstraint("ccaa", "guide_type", name="uq_legal_guide_ccaa_type"),)

    id = Column(Integer, primary_key=True, index=True)
    ccaa = Column(String(100), nullable=False, index=True)
    guide_type = Column(String(100), nullable=False, index=True)
    response_json = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class AiMarketPriceCache(Base):
    __tablename__ = "ai_market_price_cache"
    __table_args__ = (UniqueConstraint("postal_code", "property_type", name="uq_market_price_key"),)

    id = Column(Integer, primary_key=True, index=True)
    postal_code = Column(String(10), nullable=False, index=True)
    property_type = Column(String(50), nullable=False)
    response_json = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class AiMarketGapCache(Base):
    __tablename__ = "ai_market_gap_cache"
    __table_args__ = (UniqueConstraint("postal_code", name="uq_market_gap_postal"),)

    id = Column(Integer, primary_key=True, index=True)
    postal_code = Column(String(10), nullable=False, index=True)
    response_json = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class AiUrbanGrowthCache(Base):
    __tablename__ = "ai_urban_growth_cache"
    __table_args__ = (UniqueConstraint("postal_code", name="uq_urban_growth_postal"),)

    id = Column(Integer, primary_key=True, index=True)
    postal_code = Column(String(10), nullable=False, index=True)
    response_json = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class AiNeighborhoodTwinsCache(Base):
    __tablename__ = "ai_neighborhood_twins_cache"
    __table_args__ = (UniqueConstraint("cache_key", name="uq_neighborhood_twins_key"),)

    id = Column(Integer, primary_key=True, index=True)
    cache_key = Column(String(64), nullable=False, index=True)
    response_json = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class AiPriceValidationCache(Base):
    __tablename__ = "ai_price_validation_cache"
    __table_args__ = (UniqueConstraint("cache_key", name="uq_price_validation_key"),)

    id = Column(Integer, primary_key=True, index=True)
    cache_key = Column(String(64), nullable=False, index=True)
    response_json = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
