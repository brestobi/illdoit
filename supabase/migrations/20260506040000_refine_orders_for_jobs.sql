-- Update orders table to support jobs
ALTER TABLE public.orders ALTER COLUMN service_id DROP NOT NULL;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE;

-- Add balance column to users for easier access (already partially done in previous migrations, but let's ensure)
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS balance DECIMAL(10,2) DEFAULT 0;
