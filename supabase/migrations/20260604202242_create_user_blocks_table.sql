-- Create user_blocks table
CREATE TABLE IF NOT EXISTS public.user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);

-- Enable Row Level Security
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

-- Allow users to see who they have blocked
CREATE POLICY "Users can view their blocks" ON public.user_blocks
  FOR SELECT USING (auth.uid() = blocker_id);

-- Allow users to block someone
CREATE POLICY "Users can create blocks" ON public.user_blocks
  FOR INSERT WITH CHECK (auth.uid() = blocker_id);

-- Allow users to unblock someone
CREATE POLICY "Users can delete their blocks" ON public.user_blocks
  FOR DELETE USING (auth.uid() = blocker_id);
