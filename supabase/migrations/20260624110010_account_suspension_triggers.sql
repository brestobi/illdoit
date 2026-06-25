-- Migration: Auto-suspend users on accumulated pending reports
-- Date: 2026-06-24
--
-- When a user accumulates 3 or more pending reports, their account
-- is automatically suspended to prevent further harm while admin reviews.

CREATE OR REPLACE FUNCTION public.auto_suspend_on_reports()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  pending_count INTEGER;
BEGIN
  -- Count pending reports against the target user
  SELECT COUNT(*) INTO pending_count
  FROM public.user_reports
  WHERE target_id = NEW.target_id
    AND status = 'pending';

  -- Auto-suspend if threshold reached (3+ pending reports)
  IF pending_count >= 3 THEN
    UPDATE public.users
    SET account_status = 'suspended',
        suspension_reason = 'Auto-suspended: accumulated ' || pending_count || ' pending reports from other users',
        updated_at = NOW()
    WHERE id = NEW.target_id
      AND account_status = 'active';  -- Don't override an existing ban
  END IF;

  RETURN NEW;
END;
$$;

-- Drop existing trigger if re-running migration
DROP TRIGGER IF EXISTS trigger_auto_suspend_on_reports ON public.user_reports;

-- Apply trigger on INSERT to user_reports
CREATE TRIGGER trigger_auto_suspend_on_reports
  AFTER INSERT ON public.user_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_suspend_on_reports();
