-- AI Cache Tables Migration
-- Run once against the production/staging database.
-- All tables use expires_at for TTL-based invalidation; the application
-- handles eviction by checking expires_at < NOW() and overwriting the row.

-- 1. Comfort Index  (TTL 30 days, keyed by property_id)
CREATE TABLE IF NOT EXISTS ai_comfort_index_cache (
    id          SERIAL PRIMARY KEY,
    property_id VARCHAR(50)  NOT NULL,
    response_json TEXT        NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ  NOT NULL,
    CONSTRAINT uq_comfort_property UNIQUE (property_id)
);

-- 2. Legal Guides  (TTL 90 days, keyed by ccaa + guide_type)
CREATE TABLE IF NOT EXISTS ai_legal_guide_cache (
    id          SERIAL PRIMARY KEY,
    ccaa        VARCHAR(100) NOT NULL,
    guide_type  VARCHAR(100) NOT NULL,
    response_json TEXT        NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ  NOT NULL,
    CONSTRAINT uq_legal_guide_ccaa_type UNIQUE (ccaa, guide_type)
);

-- 3. Market Price  (TTL 7 days, keyed by postal_code + property_type)
CREATE TABLE IF NOT EXISTS ai_market_price_cache (
    id            SERIAL PRIMARY KEY,
    postal_code   VARCHAR(10)  NOT NULL,
    property_type VARCHAR(50)  NOT NULL,
    response_json TEXT         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at    TIMESTAMPTZ  NOT NULL,
    CONSTRAINT uq_market_price_key UNIQUE (postal_code, property_type)
);

-- 4. Market Gap  (TTL 7 days, keyed by postal_code)
CREATE TABLE IF NOT EXISTS ai_market_gap_cache (
    id            SERIAL PRIMARY KEY,
    postal_code   VARCHAR(10)  NOT NULL,
    response_json TEXT         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at    TIMESTAMPTZ  NOT NULL,
    CONSTRAINT uq_market_gap_postal UNIQUE (postal_code)
);

-- 5. Urban Growth  (TTL 30 days, keyed by postal_code)
CREATE TABLE IF NOT EXISTS ai_urban_growth_cache (
    id            SERIAL PRIMARY KEY,
    postal_code   VARCHAR(10)  NOT NULL,
    response_json TEXT         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at    TIMESTAMPTZ  NOT NULL,
    CONSTRAINT uq_urban_growth_postal UNIQUE (postal_code)
);

-- 6. Neighborhood Twins  (TTL 30 days, keyed by SHA-256 hash of postal_code + sorted lifestyle filters)
CREATE TABLE IF NOT EXISTS ai_neighborhood_twins_cache (
    id            SERIAL PRIMARY KEY,
    cache_key     VARCHAR(64)  NOT NULL,
    response_json TEXT         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at    TIMESTAMPTZ  NOT NULL,
    CONSTRAINT uq_neighborhood_twins_key UNIQUE (cache_key)
);

-- 7. Price Validation  (TTL 24 hours, keyed by SHA-256 hash of postal_code + price-per-m2 band + pct-diff band)
CREATE TABLE IF NOT EXISTS ai_price_validation_cache (
    id            SERIAL PRIMARY KEY,
    cache_key     VARCHAR(64)  NOT NULL,
    response_json TEXT         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at    TIMESTAMPTZ  NOT NULL,
    CONSTRAINT uq_price_validation_key UNIQUE (cache_key)
);

-- Indexes for fast lookups (the UNIQUE constraints already create indexes on
-- the key columns, but explicit ones on expires_at help periodic cleanup queries)
CREATE INDEX IF NOT EXISTS idx_comfort_expires    ON ai_comfort_index_cache    (expires_at);
CREATE INDEX IF NOT EXISTS idx_legal_expires      ON ai_legal_guide_cache      (expires_at);
CREATE INDEX IF NOT EXISTS idx_mktprice_expires   ON ai_market_price_cache     (expires_at);
CREATE INDEX IF NOT EXISTS idx_mktgap_expires     ON ai_market_gap_cache       (expires_at);
CREATE INDEX IF NOT EXISTS idx_urban_expires      ON ai_urban_growth_cache     (expires_at);
CREATE INDEX IF NOT EXISTS idx_twins_expires      ON ai_neighborhood_twins_cache (expires_at);
CREATE INDEX IF NOT EXISTS idx_priceval_expires   ON ai_price_validation_cache  (expires_at);
