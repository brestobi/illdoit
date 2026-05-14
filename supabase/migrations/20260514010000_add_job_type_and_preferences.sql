-- Add job_type to jobs table
ALTER TABLE public.jobs 
ADD COLUMN IF NOT EXISTS job_type TEXT DEFAULT 'digital'; -- digital, physical

-- Add preferred_job_type to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS preferred_job_type TEXT DEFAULT 'both'; -- digital, physical, both
