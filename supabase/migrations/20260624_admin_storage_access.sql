-- Migration: Admin read access to verification-docs storage bucket
-- Date: 2026-06-24
--
-- Grants admins read-only access to the verification-docs bucket
-- so they can review uploaded identity documents during verification.

-- Admin read access to verification-docs bucket
CREATE POLICY "Admins can read verification documents" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'verification-docs'
    AND public.is_admin(auth.uid())
  );
