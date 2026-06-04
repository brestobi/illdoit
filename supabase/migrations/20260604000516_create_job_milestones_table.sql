-- Create job_milestones table
CREATE TABLE IF NOT EXISTS public.job_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending', -- pending, completed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.job_milestones ENABLE ROW LEVEL SECURITY;

-- Allow users to read milestones for jobs they are involved in
CREATE POLICY "Users can read job milestones" ON public.job_milestones
  FOR SELECT USING (
    auth.uid() IN (
      SELECT client_id FROM public.jobs WHERE id = job_milestones.job_id
      UNION
      SELECT seller_id FROM public.orders WHERE job_id = job_milestones.job_id
    )
  );

-- Allow providers to update milestones for jobs they are assigned to
CREATE POLICY "Providers can update job milestones" ON public.job_milestones
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT seller_id FROM public.orders WHERE job_id = job_milestones.job_id
    )
  );

-- Allow providers to insert milestones for jobs they are assigned to
CREATE POLICY "Providers can insert job milestones" ON public.job_milestones
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT seller_id FROM public.orders WHERE job_id = job_milestones.job_id
    )
  );
