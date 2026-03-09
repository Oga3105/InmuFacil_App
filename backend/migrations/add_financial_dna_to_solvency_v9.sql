-- Migration: Sprint V9 — ADN Financiero (quantitative fields for property viability)
-- Adds encrypted quantitative financial fields to buyer_solvency table.
-- All three fields are AES-256-GCM encrypted strings (never stored in plain text).
-- Date: 2026-03-09

ALTER TABLE buyer_solvency
    ADD COLUMN IF NOT EXISTS net_monthly_income_enc  TEXT,
    ADD COLUMN IF NOT EXISTS total_savings_enc        TEXT,
    ADD COLUMN IF NOT EXISTS total_monthly_debt_enc   TEXT;
