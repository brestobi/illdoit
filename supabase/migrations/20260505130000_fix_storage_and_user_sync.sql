-- Migration to fix Storage RLS and User Integrity

-- 1. Sync any missing users from auth.users to public.users
-- This fixes the "Key is not present in table users" error for users created before the trigger was active
INSERT INTO public.users (id, email, display_name)
SELECT id, email, COALESCE(raw_user_meta_data->>'full_name', email)
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 2. Storage Buckets Setup
-- Create the necessary buckets if they don't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('service-images', 'service-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('job-images', 'job-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('verification-docs', 'verification-docs', false)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage Policies

-- Delete existing policies to avoid conflicts if re-running
DROP POLICY IF EXISTS "Avatars are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Service images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload service images" ON storage.objects;
DROP POLICY IF EXISTS "Job images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload job images" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own verification docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own verification docs" ON storage.objects;

-- Avatars Policies
CREATE POLICY "Avatars are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = name);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND auth.uid()::text = name);

-- Service Images Policies
CREATE POLICY "Service images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'service-images');

CREATE POLICY "Users can upload service images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'service-images' AND (storage.foldername(name))[2] = auth.uid()::text);

-- Job Images Policies
CREATE POLICY "Job images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'job-images');

CREATE POLICY "Users can upload job images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'job-images' AND (storage.foldername(name))[2] = auth.uid()::text);

-- Verification Docs Policies
CREATE POLICY "Users can view their own verification docs"
ON storage.objects FOR SELECT
USING (bucket_id = 'verification-docs' AND (storage.foldername(name))[2] = auth.uid()::text);

CREATE POLICY "Users can upload their own verification docs"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'verification-docs' AND (storage.foldername(name))[2] = auth.uid()::text);
