-- Payments and Escrow Migration

-- Add order_id to transactions
ALTER TABLE public.transactions ADD COLUMN order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

-- Withdrawal Requests Table
CREATE TABLE public.withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  bank_name VARCHAR(255) NOT NULL,
  account_holder VARCHAR(255) NOT NULL,
  account_number VARCHAR(50) NOT NULL,
  branch_code VARCHAR(20) NOT NULL,
  account_type VARCHAR(50) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending', -- pending, processed, rejected
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on withdrawal_requests
ALTER TABLE public.withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Withdrawal Requests Policies
CREATE POLICY "Users can view their own withdrawal requests" 
ON public.withdrawal_requests FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create withdrawal requests" 
ON public.withdrawal_requests FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Update users table to track escrow balance (optional, can be calculated)
-- But let's add it for performance
ALTER TABLE public.users ADD COLUMN escrow_balance DECIMAL(10,2) DEFAULT 0;
