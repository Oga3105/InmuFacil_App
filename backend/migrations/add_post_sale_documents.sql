-- Migration: create post_sale_documents table
-- Sprint V7: Post-Sale document management (electricity, water, gas, IBI, community)
-- Gate: documents only accessible after DEED_SIGNATURE step is COMPLETED
-- Date: 2026-03-08

CREATE TYPE postsaledoctype AS ENUM (
    'electricity',
    'water',
    'gas',
    'ibi',
    'community'
);

CREATE TABLE IF NOT EXISTS post_sale_documents (
    id           SERIAL PRIMARY KEY,
    offer_id     INTEGER NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
    uploaded_by  INTEGER NOT NULL REFERENCES users(id),
    doc_type     postsaledoctype NOT NULL,
    filename     VARCHAR NOT NULL,
    file_path    VARCHAR NOT NULL,
    file_size    INTEGER,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_post_sale_documents_offer_id ON post_sale_documents(offer_id);
