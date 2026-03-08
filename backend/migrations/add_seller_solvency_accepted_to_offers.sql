-- Migration: add seller_solvency_accepted columns to offers table
-- Sprint V5 Fase 2: Seller must review buyer solvency passport before timeline advances
-- Date: 2026-03-08

ALTER TABLE offers
    ADD COLUMN IF NOT EXISTS seller_solvency_accepted BOOLEAN,
    ADD COLUMN IF NOT EXISTS seller_solvency_accepted_at TIMESTAMP WITH TIME ZONE;
