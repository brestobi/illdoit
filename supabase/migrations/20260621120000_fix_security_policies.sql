-- Migration: Fix Security Policies (2026-06-21)
-- 1. Secure public_profiles view
CREATE OR REPLACE VIEW public.public_profiles 
WITH (security_invoker = true) AS
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

-- 2. Define secure admin check function
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND user_type = 'admin'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 3. Drop insecure Admin policies
DROP POLICY IF EXISTS "Admin read all users" ON public.users;
DROP POLICY IF EXISTS "Admin read withdrawals" ON public.withdrawal_requests;
DROP POLICY IF EXISTS "Admin read disputes" ON public.disputes;
DROP POLICY IF EXISTS "Admin read orders" ON public.orders;
DROP POLICY IF EXISTS "Admin manage jobs" ON public.jobs;
DROP POLICY IF EXISTS "Admin manage services" ON public.services;
DROP POLICY IF EXISTS "Admin read transactions" ON public.transactions;
DROP POLICY IF EXISTS "Admin manage audit logs" ON public.admin_audit_logs;

-- 4. Re-create secure Admin policies
CREATE POLICY "Admin read all users" ON public.users FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin read withdrawals" ON public.withdrawal_requests FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin read disputes" ON public.disputes FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin read orders" ON public.orders FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin manage jobs" ON public.jobs FOR ALL USING (public.is_admin());
CREATE POLICY "Admin manage services" ON public.services FOR ALL USING (public.is_admin());
CREATE POLICY "Admin read transactions" ON public.transactions FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin manage audit logs" ON public.admin_audit_logs FOR ALL USING (public.is_admin());
