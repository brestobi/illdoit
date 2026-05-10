-- Add user_type column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS user_type VARCHAR(50) DEFAULT 'viewer';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_onboarding_completed BOOLEAN DEFAULT FALSE;

-- Update the handle_new_user function to include user_type if provided in metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, user_type, is_onboarding_completed)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'full_name', new.email),
    COALESCE(new.raw_user_meta_data->>'user_type', 'viewer'),
    COALESCE((new.raw_user_meta_data->>'is_onboarding_completed')::boolean, false)
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
