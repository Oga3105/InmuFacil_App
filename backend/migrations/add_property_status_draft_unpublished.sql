-- Migration: Add draft and unpublished values to PropertyStatus enum
-- Run once against the PostgreSQL database.
-- PostgreSQL requires ALTER TYPE ... ADD VALUE to run outside of a transaction block.

ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'draft';
ALTER TYPE propertystatus ADD VALUE IF NOT EXISTS 'unpublished';
