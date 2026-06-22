-- Migration: Fix access to public_profiles (2026-06-21)

-- Views do not support RLS policies directly.
-- Instead, we ensure the correct roles have SELECT permission on the view.

REVOKE ALL ON public.public_profiles FROM authenticated, anon;
GRANT SELECT ON public.public_profiles TO authenticated, anon;
