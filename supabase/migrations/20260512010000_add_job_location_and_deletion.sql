-- Add location column to jobs table
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS location VARCHAR(100);

-- Update RLS policies to allow deletion by owner
CREATE POLICY "Users can delete their own jobs"
ON public.jobs FOR DELETE USING (auth.uid() = client_id);
