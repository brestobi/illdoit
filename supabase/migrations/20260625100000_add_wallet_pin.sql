-- Migration: Add wallet PIN hash to users table
-- Date: 2026-06-25
--
-- Stores a SHA-256 hash of the user's wallet PIN in the database,
-- scoped per-user so switching accounts always uses the correct PIN.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'pin_hash'
  ) THEN
    ALTER TABLE public.users ADD COLUMN pin_hash TEXT;
  END IF;
END $$;
