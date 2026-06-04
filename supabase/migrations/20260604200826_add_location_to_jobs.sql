-- Add location columns to jobs table
ALTER TABLE public.jobs
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Create an index for faster location-based queries
CREATE INDEX IF NOT EXISTS idx_jobs_location ON public.jobs (latitude, longitude);
