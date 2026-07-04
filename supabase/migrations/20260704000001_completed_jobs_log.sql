-- ============================================================================
-- Migration 002: Completed jobs audit log
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================================

-- 1. Create a completed_jobs log table for admin reference
--    Captures every job completion with metadata for auditing.
CREATE TABLE IF NOT EXISTS completed_jobs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id        UUID NOT NULL REFERENCES jobs(id) ON DELETE SET NULL,
  title         TEXT NOT NULL,
  category      TEXT,
  budget        NUMERIC(10,2),
  client_id     UUID REFERENCES users(id),
  worker_id     UUID REFERENCES users(id),
  completed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Auto-log when a job is marked completed
CREATE OR REPLACE FUNCTION log_completed_job()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    INSERT INTO completed_jobs (job_id, title, category, budget, client_id, worker_id)
    VALUES (NEW.id, NEW.title, NEW.category, NEW.budget, NEW.client_id, NEW.worker_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Apply the trigger (idempotent)
DROP TRIGGER IF EXISTS trg_log_completed_job ON jobs;
CREATE TRIGGER trg_log_completed_job
  AFTER UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION log_completed_job();

-- 4. Index for admin queries
CREATE INDEX IF NOT EXISTS idx_completed_jobs_completed_at ON completed_jobs(completed_at DESC);
