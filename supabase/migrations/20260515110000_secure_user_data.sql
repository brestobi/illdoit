-- Migration: Secure user data by creating a public profiles view and restricting access to the users table
-- Created: 2026-05-15

-- 1. Create a view for public profile information
-- This view only includes columns that are safe to share publicly
CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
    id,
    display_name,
    bio,
    avatar_url,
    location,
    user_type,
    preferred_job_type,
    skills,
    rating,
    completed_jobs,
    is_verified,
    is_profile_public,
    show_last_seen,
    show_contact_info,
    created_at,
    updated_at
FROM
    public.users
WHERE
    is_profile_public = true;

-- 2. Revoke all access from the view first to be safe
REVOKE ALL ON public.public_profiles FROM public, authenticated, anon;

-- 3. Grant select access to the view for authenticated and anonymous users
GRANT SELECT ON public.public_profiles TO authenticated, anon;

-- 4. Update RLS policies on the users table to be more restrictive
-- Only allow the owner to see their full record in the users table

-- First, drop the overly permissive policy
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Users can view all profiles" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;

-- Create the new restrictive policy
CREATE POLICY "Users can only view their own full profile"
ON public.users FOR SELECT
USING (auth.uid() = id);

-- Ensure only the owner can update their profile (already exists, but reinforcing)
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 5. Add a comment to the view for documentation
COMMENT ON VIEW public.public_profiles IS 'Secure view for public user profiles, excluding sensitive data.';
