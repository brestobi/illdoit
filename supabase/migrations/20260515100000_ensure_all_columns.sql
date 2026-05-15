-- Migration: Ensure all missing columns exist in users and jobs tables
-- Created: 2026-05-15

-- Update users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS user_type VARCHAR(50) DEFAULT 'viewer',
ADD COLUMN IF NOT EXISTS preferred_job_type TEXT DEFAULT 'both',
ADD COLUMN IF NOT EXISTS is_onboarding_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS push_token TEXT,
ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'unverified',
ADD COLUMN IF NOT EXISTS verification_metadata JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS real_name TEXT,
ADD COLUMN IF NOT EXISTS id_number TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS bank_name TEXT,
ADD COLUMN IF NOT EXISTS bank_account_number TEXT,
ADD COLUMN IF NOT EXISTS bank_account_type TEXT,
ADD COLUMN IF NOT EXISTS bank_branch_code TEXT,
ADD COLUMN IF NOT EXISTS balance DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS escrow_balance DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS is_profile_public BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_last_seen BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_contact_info BOOLEAN DEFAULT FALSE;

-- Update jobs table
ALTER TABLE public.jobs
ADD COLUMN IF NOT EXISTS job_type TEXT DEFAULT 'digital',
ADD COLUMN IF NOT EXISTS location VARCHAR(255);

-- Create missing tables if they don't exist
CREATE TABLE IF NOT EXISTS public.locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  icon TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  category TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.id_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.supported_banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
