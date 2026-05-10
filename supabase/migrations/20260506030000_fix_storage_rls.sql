-- Fix Storage RLS policies and resolve User Profile/FK errors

-- 0. Fix Users table and trigger for phone users
ALTER TABLE public.users ALTER COLUMN email DROP NOT NULL;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, phone, display_name, user_type, is_onboarding_completed)
  VALUES (
    new.id, 
    new.email,
    new.phone,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'display_name', new.email, new.phone, 'User'),
    COALESCE(new.raw_user_meta_data->>'user_type', 'viewer'),
    COALESCE((new.raw_user_meta_data->>'is_onboarding_completed')::boolean, false)
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    display_name = EXCLUDED.display_name;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. Avatars Policies
DROP POLICY IF EXISTS "Avatars are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;

CREATE POLICY "Avatars are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 2. Service Images Policies
DROP POLICY IF EXISTS "Service images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload service images" ON storage.objects;

CREATE POLICY "Service images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'service-images');

CREATE POLICY "Users can upload service images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'service-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 3. Job Images Policies
DROP POLICY IF EXISTS "Job images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload job images" ON storage.objects;

CREATE POLICY "Job images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'job-images');

CREATE POLICY "Users can upload job images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'job-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 4. Verification Docs Policies
DROP POLICY IF EXISTS "Users can view their own verification docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own verification docs" ON storage.objects;

CREATE POLICY "Users can view their own verification docs"
ON storage.objects FOR SELECT
USING (bucket_id = 'verification-docs' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can upload their own verification docs"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'verification-docs' AND (storage.foldername(name))[1] = auth.uid()::text);
