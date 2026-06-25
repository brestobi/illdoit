-- Migration: Fix public_profiles view security_invoker
-- Date: 2026-06-25
--
-- The previous migration (20260621120000) set security_invoker = true on the
-- public_profiles view. This caused the view to run with the caller's permissions,
-- which meant the RLS policy "Users can only view their own full profile" on the
-- users table filtered out all rows except the caller's own profile.
--
-- This meant querying public_profiles for another user (e.g. a seller) returned
-- zero rows, causing "Error loading seller" throughout the app.
--
-- Fix: Recreate the view WITHOUT security_invoker, so it runs with the owner's
-- privileges (typically postgres) and bypasses the users table RLS. The view
-- already restricts which columns are exposed, so sensitive data is still safe.

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

-- Re-grant access
REVOKE ALL ON public.public_profiles FROM public, authenticated, anon;
GRANT SELECT ON public.public_profiles TO authenticated, anon;

COMMENT ON VIEW public.public_profiles IS 'Public user profiles (no security_invoker — bypasses users table RLS to allow viewing other profiles).';
