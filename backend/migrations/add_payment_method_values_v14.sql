-- Sprint V14: Add new PaymentMethod enum values to PostgreSQL
-- SAVINGS_ONLY: buyer pays with savings only, no bank involved yet
-- NO_PROCESS:   buyer has not started any financing process
--
-- NOTE: This project stores Python enum *names* (uppercase) in the DB column,
-- matching SQLAlchemy's default behaviour for native Python enums.
-- PostgreSQL does not allow removing enum values; only ADD VALUE is safe.
-- Run once against the target database.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'SAVINGS_ONLY'
          AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'paymentmethod')
    ) THEN
        ALTER TYPE paymentmethod ADD VALUE 'SAVINGS_ONLY';
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'NO_PROCESS'
          AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'paymentmethod')
    ) THEN
        ALTER TYPE paymentmethod ADD VALUE 'NO_PROCESS';
    END IF;
END$$;
