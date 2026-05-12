-- Drop the restrictive policy
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;

-- Create a new policy that allows everyone to view basic profile info
-- Note: In a production app, we would use a View or Column-level security to hide sensitive fields like email/phone
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.users;
CREATE POLICY "Public profiles are viewable by everyone"
ON public.users FOR SELECT
USING (true);

-- Ensure only the owner can update their profile
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
