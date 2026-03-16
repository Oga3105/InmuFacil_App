-- Migration: add post_sale_doc_flags table
-- Tracks non-file delivery methods (in_person, not_applicable) per doc type.

CREATE TABLE IF NOT EXISTS post_sale_doc_flags (
    id         SERIAL PRIMARY KEY,
    offer_id   INTEGER NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
    doc_type   VARCHAR NOT NULL,
    flag       VARCHAR NOT NULL,   -- 'in_person' | 'not_applicable'
    set_by     INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uix_post_sale_doc_flags UNIQUE (offer_id, doc_type)
);

CREATE INDEX IF NOT EXISTS idx_post_sale_doc_flags_offer
    ON post_sale_doc_flags (offer_id);
