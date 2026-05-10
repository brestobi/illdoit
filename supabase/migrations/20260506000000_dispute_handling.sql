-- Dispute Handling Migration

-- 1. Add 'disputed' to OrderStatus in orders table (represented as string)
-- No changes needed if using VARCHAR for status, but let's ensure the constraint allows it if it exists.

-- 2. Disputes Table
CREATE TABLE public.disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  raised_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT NOT NULL,
  status VARCHAR(50) DEFAULT 'open', -- open, under_review, resolved, cancelled
  resolution_summary TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on disputes
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;

-- Disputes Policies
CREATE POLICY "Users can view disputes related to their orders" 
ON public.disputes FOR SELECT 
USING (
  raised_by = auth.uid() OR 
  EXISTS (
    SELECT 1 FROM public.orders 
    WHERE id = order_id AND (buyer_id = auth.uid() OR seller_id = auth.uid())
  )
);

CREATE POLICY "Users can raise disputes for their orders" 
ON public.disputes FOR INSERT 
WITH CHECK (
  raised_by = auth.uid() AND
  EXISTS (
    SELECT 1 FROM public.orders 
    WHERE id = order_id AND (buyer_id = auth.uid() OR seller_id = auth.uid())
  )
);

-- 3. Function to handle dispute resolution (Simulated for MVP)
-- In a real app, this would be an admin action or a complex flow.
