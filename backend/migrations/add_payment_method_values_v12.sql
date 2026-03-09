-- Sprint V12: Add new PaymentMethod enum values to PostgreSQL
-- savings_plus_mortgage: buyer has savings + mortgage financing
-- bridge_mortgage: buyer uses a bridge mortgage (hipoteca puente)
--
-- PostgreSQL does not allow removing enum values; only ADD VALUE is safe.
-- Run once against the target database.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'savings_plus_mortgage'
          AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'paymentmethod')
    ) THEN
        ALTER TYPE paymentmethod ADD VALUE 'savings_plus_mortgage';
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'bridge_mortgage'
          AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'paymentmethod')
    ) THEN
        ALTER TYPE paymentmethod ADD VALUE 'bridge_mortgage';
    END IF;
END$$;
