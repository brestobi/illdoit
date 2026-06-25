-- Migration: Admin schema updates — user_reports, admin_audit_logs, is_admin column
-- Date: 2026-06-24
--
-- Creates tables and policies needed for admin console functionality:
-- 1. user_reports — stores user-submitted reports about other users
-- 2. admin_audit_logs — tracks all admin actions for accountability
-- 3. is_admin column on users table + helper function

-- ============================================================
-- 0. Add is_admin column to users FIRST (required by function below)
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'is_admin'
  ) THEN
    ALTER TABLE public.users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT false;
  END IF;
END $$;

-- ============================================================
-- 1. is_admin helper function (must exist BEFORE policies that use it)
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_admin(uid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = uid AND is_admin = true
  );
$$;

-- ============================================================
-- 2. user_reports table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  admin_notes TEXT,
  reviewed_by UUID REFERENCES public.users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

-- Reporters can insert their own reports
DROP POLICY IF EXISTS "Users can create reports" ON public.user_reports;
CREATE POLICY "Users can create reports" ON public.user_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Reporters can view their own reports
DROP POLICY IF EXISTS "Users can view own reports" ON public.user_reports;
CREATE POLICY "Users can view own reports" ON public.user_reports
  FOR SELECT USING (auth.uid() = reporter_id);

-- Admins can view all reports
DROP POLICY IF EXISTS "Admins can view all reports" ON public.user_reports;
CREATE POLICY "Admins can view all reports" ON public.user_reports
  FOR SELECT USING (public.is_admin(auth.uid()));

-- Admins can update reports (review/dismiss)
DROP POLICY IF EXISTS "Admins can update reports" ON public.user_reports;
CREATE POLICY "Admins can update reports" ON public.user_reports
  FOR UPDATE USING (public.is_admin(auth.uid()));

-- ============================================================
-- 3. admin_audit_logs table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES public.users(id),
  action TEXT NOT NULL,
  target_table TEXT NOT NULL,
  target_id UUID NOT NULL,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can read audit logs
DROP POLICY IF EXISTS "Admins can read audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admins can read audit logs" ON public.admin_audit_logs
  FOR SELECT USING (public.is_admin(auth.uid()));

-- Only admins can insert audit logs
DROP POLICY IF EXISTS "Admins can insert audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admins can insert audit logs" ON public.admin_audit_logs
  FOR INSERT WITH CHECK (public.is_admin(auth.uid()));
