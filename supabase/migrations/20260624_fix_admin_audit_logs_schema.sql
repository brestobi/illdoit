-- Migration: Ensure admin_audit_logs has target_table column
-- Date: 2026-06-24
--
-- Idempotent fix: ensures the target_table column exists on
-- admin_audit_logs, as it was added in admin_schema_updates but may
-- need to be retroactively applied to existing installations.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'admin_audit_logs' AND column_name = 'target_table'
  ) THEN
    ALTER TABLE public.admin_audit_logs ADD COLUMN target_table TEXT;
  END IF;
END $$;
