-- ============================================================================
-- Migration: Admin Infrastructure & Missing Tables
-- Date: 2026-06-24
-- Fixes: user_reports, admin_audit_logs, missing columns, admin RLS gaps
-- ============================================================================

-- ============================================================================
-- 1. USER REPORTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'pending',  -- pending | reviewed | dismissed
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

-- Users can report
DROP POLICY IF EXISTS "Users can create reports" ON public.user_reports;
CREATE POLICY "Users can create reports" ON public.user_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Users can view their own reports
DROP POLICY IF EXISTS "Users can view their own reports" ON public.user_reports;
CREATE POLICY "Users can view their own reports" ON public.user_reports
  FOR SELECT USING (auth.uid() = reporter_id);

-- Admin full access
DROP POLICY IF EXISTS "Admin manage reports" ON public.user_reports;
CREATE POLICY "Admin manage reports" ON public.user_reports
  FOR ALL USING (public.is_admin());

-- Add to realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_reports;


-- ============================================================================
-- 2. ADMIN AUDIT LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  action VARCHAR(100) NOT NULL,
  target_table VARCHAR(100),
  target_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Admin full access
DROP POLICY IF EXISTS "Admin manage audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admin manage audit logs" ON public.admin_audit_logs
  FOR ALL USING (public.is_admin());


-- ============================================================================
-- 3. MISSING COLUMNS ON USERS TABLE
-- ============================================================================

-- Account suspension fields
ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS account_status VARCHAR(50) DEFAULT 'active';

ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS suspension_reason TEXT;

ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS suspended_until TIMESTAMPTZ;

-- Verification rejection reason
ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS verification_rejection_reason TEXT;

-- Update existing users to active
UPDATE public.users SET account_status = 'active' WHERE account_status IS NULL;

-- Comments
COMMENT ON COLUMN public.users.account_status IS 'active | suspended | banned';
COMMENT ON COLUMN public.users.suspension_reason IS 'Reason for suspension or ban';
COMMENT ON COLUMN public.users.suspended_until IS 'When suspension ends (null = permanent)';
COMMENT ON COLUMN public.users.verification_rejection_reason IS 'Reason for rejecting verification';


-- ============================================================================
-- 4. MISSING COLUMNS ON TRANSACTIONS TABLE
-- ============================================================================

-- Payment tracking
ALTER TABLE public.transactions 
  ADD COLUMN IF NOT EXISTS payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.transactions.payment_id IS 'Links deposit transactions to their payment record';


-- ============================================================================
-- 5. PLATFORM FEES CONFIGURATION
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.platform_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(100) UNIQUE NOT NULL,
  value TEXT NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.platform_config ENABLE ROW LEVEL SECURITY;

-- Public read
CREATE POLICY "Public can read platform config" ON public.platform_config
  FOR SELECT USING (true);

-- Admin write
CREATE POLICY "Admin manage platform config" ON public.platform_config
  FOR ALL USING (public.is_admin());

-- Seed default config values
INSERT INTO public.platform_config (key, value, description) VALUES
  ('platform_fee_percent', '10', 'Platform fee percentage per transaction'),
  ('min_withdrawal_amount', '50', 'Minimum withdrawal amount in ZAR'),
  ('min_deposit_amount', '10', 'Minimum deposit amount in ZAR'),
  ('maintenance_mode', 'false', 'Enable maintenance mode'),
  ('max_reports_before_auto_suspend', '5', 'Auto-suspend user after N reports')
ON CONFLICT (key) DO NOTHING;


-- ============================================================================
-- 6. ADMIN RLS POLICIES — WRITE ACCESS WHERE MISSING
-- ============================================================================

-- Users: admin needs UPDATE for suspend/ban/verify
DROP POLICY IF EXISTS "Admin update users" ON public.users;
CREATE POLICY "Admin update users" ON public.users
  FOR UPDATE USING (public.is_admin());

-- Withdrawal requests: admin needs ALL
DROP POLICY IF EXISTS "Admin manage withdrawals" ON public.withdrawal_requests;
CREATE POLICY "Admin manage withdrawals" ON public.withdrawal_requests
  FOR ALL USING (public.is_admin());

-- Disputes: admin needs ALL
DROP POLICY IF EXISTS "Admin manage disputes" ON public.disputes;
CREATE POLICY "Admin manage disputes" ON public.disputes
  FOR ALL USING (public.is_admin());

-- Orders: admin needs UPDATE for status changes
DROP POLICY IF EXISTS "Admin update orders" ON public.orders;
CREATE POLICY "Admin update orders" ON public.orders
  FOR UPDATE USING (public.is_admin());

-- Transactions: admin needs full access
DROP POLICY IF EXISTS "Admin manage transactions" ON public.transactions;
CREATE POLICY "Admin manage transactions" ON public.transactions
  FOR ALL USING (public.is_admin());

-- Messages: admin needs SELECT for dispute investigation
CREATE POLICY "Admin read messages" ON public.messages
  FOR SELECT USING (public.is_admin());

-- Reviews: admin needs ALL for moderation
CREATE POLICY "Admin manage reviews" ON public.reviews
  FOR ALL USING (public.is_admin());

-- Notifications: admin needs ALL for broadcast
CREATE POLICY "Admin manage notifications" ON public.notifications
  FOR ALL USING (public.is_admin());

-- Payments: admin needs ALL for Yoco transaction audit
CREATE POLICY "Admin manage payments" ON public.payments
  FOR ALL USING (public.is_admin());

-- User blocks: admin needs SELECT for safety review
CREATE POLICY "Admin read user blocks" ON public.user_blocks
  FOR SELECT USING (public.is_admin());

-- Job applications: admin needs SELECT
CREATE POLICY "Admin read job applications" ON public.job_applications
  FOR SELECT USING (public.is_admin());

-- Job milestones: admin needs SELECT
CREATE POLICY "Admin read job milestones" ON public.job_milestones
  FOR SELECT USING (public.is_admin());


-- ============================================================================
-- 7. STORAGE — ADMIN ACCESS TO VERIFICATION DOCS
-- ============================================================================
CREATE POLICY "Admin can read all verification docs" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'verification-docs' AND public.is_admin()
  );

CREATE POLICY "Admin can read all avatars" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'avatars' AND public.is_admin()
  );

CREATE POLICY "Admin can read all service images" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'service-images' AND public.is_admin()
  );

CREATE POLICY "Admin can read all job images" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'job-images' AND public.is_admin()
  );


-- ============================================================================
-- 8. UTILITY — AUDIT LOG HELPER FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION public.log_admin_action(
  p_action VARCHAR,
  p_target_table VARCHAR,
  p_target_id UUID,
  p_old_data JSONB DEFAULT NULL,
  p_new_data JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO public.admin_audit_logs (
    admin_id, action, target_table, target_id, old_data, new_data
  ) VALUES (
    auth.uid(), p_action, p_target_table, p_target_id, p_old_data, p_new_data
  ) RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- 9. VERIFICATION — TRIGGER FOR STATUS CHANGE AUDIT
-- ============================================================================
CREATE OR REPLACE FUNCTION public.audit_verification_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.verification_status IS DISTINCT FROM OLD.verification_status) THEN
    INSERT INTO public.admin_audit_logs (admin_id, action, target_table, target_id, old_data, new_data)
    VALUES (
      auth.uid(),
      CASE
        WHEN NEW.verification_status = 'verified' THEN 'verify_user_approved'
        WHEN NEW.verification_status = 'rejected' THEN 'verify_user_rejected'
        ELSE 'verification_status_changed'
      END,
      'users',
      NEW.id,
      jsonb_build_object('verification_status', OLD.verification_status, 'is_verified', OLD.is_verified),
      jsonb_build_object('verification_status', NEW.verification_status, 'is_verified', NEW.is_verified)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_verification_change ON public.users;
CREATE TRIGGER on_verification_change
  AFTER UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.audit_verification_change();


-- ============================================================================
-- 10. NOTIFICATION — FUNCTION FOR ADMIN BROADCASTS
-- ============================================================================
CREATE OR REPLACE FUNCTION public.broadcast_notification(
  p_type VARCHAR,
  p_title VARCHAR,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::jsonb,
  p_user_type_filter VARCHAR DEFAULT NULL
) RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  INSERT INTO public.notifications (user_id, type, title, body, data)
  SELECT id, p_type, p_title, p_body, p_data
  FROM public.users
  WHERE 
    account_status = 'active' 
    AND (p_user_type_filter IS NULL OR user_type = p_user_type_filter);

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
