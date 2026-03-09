-- Sprint V10: Multi-buyer flag for BuyerSolvency
-- is_multi_buyer: TRUE when the purchase involves two or more buyers.
--   Financial fields (net_monthly_income_enc, total_savings_enc, total_monthly_debt_enc)
--   are treated as the SUM of all buyers' figures.

ALTER TABLE buyer_solvency
    ADD COLUMN IF NOT EXISTS is_multi_buyer BOOLEAN NOT NULL DEFAULT FALSE;
