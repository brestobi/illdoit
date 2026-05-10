-- Add missing columns for verification tracking
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'unverified',
ADD COLUMN IF NOT EXISTS verification_metadata JSONB DEFAULT '{}'::jsonb;

-- Update existing unverified users
UPDATE public.users SET verification_status = 'unverified' WHERE verification_status IS NULL;

-- Comment for clarity
COMMENT ON COLUMN public.users.verification_status IS 'unverified, pending, verified, rejected';
