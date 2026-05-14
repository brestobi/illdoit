-- Add verification and banking fields to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS real_name TEXT,
ADD COLUMN IF NOT EXISTS id_number TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS bank_name TEXT,
ADD COLUMN IF NOT EXISTS bank_account_number TEXT,
ADD COLUMN IF NOT EXISTS bank_account_type TEXT,
ADD COLUMN IF NOT EXISTS bank_branch_code TEXT,
ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'unverified'; -- unverified, pending, verified, rejected

-- Update existing is_verified flag based on status if needed (optional)
-- UPDATE public.users SET is_verified = (verification_status = 'verified');
