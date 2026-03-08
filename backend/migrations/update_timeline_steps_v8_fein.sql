-- Migration: Sprint V8 - Split MORTGAGE_APPROVAL into TASACION_APPOINTMENT + FEIN_CONFIRMATION
-- Existing MORTGAGE_APPROVAL step (order 5) is renamed to TASACION_APPOINTMENT.
-- New FEIN_CONFIRMATION step added at order 6.
-- NOTARY_ASSIGNMENT moves to order 7, DEED_SIGNATURE to order 8.
-- Date: 2026-03-08

-- Rename existing MORTGAGE_APPROVAL to TASACION_APPOINTMENT
UPDATE transaction_steps
SET step_key  = 'TASACION_APPOINTMENT',
    label     = 'Tasacion de la Vivienda',
    description = 'El tasador visita la vivienda y emite el informe de valor de mercado.'
WHERE step_key = 'MORTGAGE_APPROVAL';

-- Shift existing higher-order steps up by 1 to make room for FEIN at order 6
UPDATE transaction_steps SET step_order = 8 WHERE step_key = 'DEED_SIGNATURE';
UPDATE transaction_steps SET step_order = 7 WHERE step_key = 'NOTARY_ASSIGNMENT';

-- Insert FEIN_CONFIRMATION step for all existing offers that have a timeline
-- (inherits offer_id from TASACION_APPOINTMENT siblings)
INSERT INTO transaction_steps (offer_id, step_order, step_key, label, description, required_role, status, created_at, updated_at)
SELECT
    offer_id,
    6,
    'FEIN_CONFIRMATION',
    'Formalizacion Bancaria (FEIN)',
    'El banco emite la FEIN/FIPER y confirma la viabilidad economica final.',
    'BUYER',
    'PENDING',
    NOW(),
    NOW()
FROM transaction_steps
WHERE step_key = 'TASACION_APPOINTMENT'
ON CONFLICT DO NOTHING;
