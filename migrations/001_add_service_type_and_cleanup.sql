-- ============================================================================
-- Migration 001: Service type + expired job cleanup
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================================

-- 1. Add service_type column to services table
--    Used by the create/edit service screen to distinguish digital vs physical
--    services (Screen #13).
ALTER TABLE services
  ADD COLUMN IF NOT EXISTS service_type TEXT DEFAULT 'digital';

-- Update any existing rows to 'digital' so they're not null
UPDATE services SET service_type = 'digital' WHERE service_type IS NULL;

-- 2. Cron job: auto-delete open jobs past their deadline
--    Runs every hour to clean up expired open jobs.
--    Requires pg_cron extension to be enabled in Supabase.
--    (Screen #16)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
    -- Remove old schedule if it exists (idempotent re-run)
    PERFORM cron.unschedule('cleanup-expired-jobs');

    -- Schedule: every hour, delete open jobs past deadline
    PERFORM cron.schedule(
      'cleanup-expired-jobs',
      '0 * * * *',
      $$
        DELETE FROM jobs WHERE status = 'open' AND deadline < now();
      $$
    );
  ELSE
    RAISE NOTICE 'pg_cron extension is not enabled — expired job cleanup will rely on client-side only.';
  END IF;
END $$;
