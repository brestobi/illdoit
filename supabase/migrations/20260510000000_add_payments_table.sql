-- Create payments table to track payment attempts
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(10) DEFAULT 'ZAR',
  status VARCHAR(50) DEFAULT 'pending', -- pending, successful, failed
  reference VARCHAR(255) UNIQUE NOT NULL,
  external_id VARCHAR(255), -- Yoco checkout ID
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE tablename = 'payments'
          AND policyname = 'Users can view their own payments'
    ) THEN
        CREATE POLICY "Users can view their own payments"
        ON payments FOR SELECT
        USING (auth.uid() = user_id);
    END IF;
END
$$;

-- Only service role or webhooks should be able to update/insert without user context if needed, 
-- but for now let's allow the user to see their own status.
