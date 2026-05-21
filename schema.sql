-- I'll Do It - Complete Database Schema
-- Updated: 2026-05-21

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (Profiles)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  display_name VARCHAR(255) NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  location VARCHAR(255),
  user_type VARCHAR(50) DEFAULT 'viewer', -- viewer, worker, client, both
  preferred_job_type TEXT DEFAULT 'both', -- digital, physical, both
  is_onboarding_completed BOOLEAN DEFAULT FALSE,
  push_token TEXT,
  skills TEXT[] DEFAULT ARRAY[]::TEXT[],
  rating DECIMAL(3,1) DEFAULT 0,
  completed_jobs INT DEFAULT 0,
  is_verified BOOLEAN DEFAULT FALSE,
  verification_status TEXT DEFAULT 'unverified', -- unverified, pending, verified, rejected
  verification_metadata JSONB DEFAULT '{}'::jsonb,
  real_name TEXT,
  id_number TEXT,
  address TEXT,
  bank_name TEXT,
  bank_account_number TEXT,
  bank_account_type TEXT,
  bank_branch_code TEXT,
  balance DECIMAL(12,2) DEFAULT 0.00,
  escrow_balance DECIMAL(12,2) DEFAULT 0.00,
  is_profile_public BOOLEAN DEFAULT TRUE,
  show_last_seen BOOLEAN DEFAULT TRUE,
  show_contact_info BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Public Profiles View (Safe to share publicly)
CREATE OR REPLACE VIEW public.public_profiles AS
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

-- Grant select access to public_profiles
GRANT SELECT ON public.public_profiles TO authenticated, anon;

-- Services table
CREATE TABLE IF NOT EXISTS public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  delivery_time INT NOT NULL,
  images TEXT[] DEFAULT ARRAY[]::TEXT[],
  rating DECIMAL(3,1) DEFAULT 0,
  total_orders INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Jobs table
CREATE TABLE IF NOT EXISTS public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  job_type TEXT DEFAULT 'digital', -- digital, physical
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  location VARCHAR(255),
  budget DECIMAL(10,2) NOT NULL,
  deadline TIMESTAMP WITH TIME ZONE NOT NULL,
  status VARCHAR(50) DEFAULT 'open', -- open, in_progress, completed, cancelled
  images TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  type VARCHAR(50) NOT NULL, -- deposit, withdrawal, payment, refund, fee
  status VARCHAR(50) DEFAULT 'pending', -- pending, completed, failed, cancelled
  reference VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Locations table
CREATE TABLE IF NOT EXISTS public.locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  icon TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Skills table
CREATE TABLE IF NOT EXISTS public.skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  category TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ID Types table
CREATE TABLE IF NOT EXISTS public.id_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Supported Banks table
CREATE TABLE IF NOT EXISTS public.supported_banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies

-- Users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only view their own full profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Services
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Services are readable by everyone" ON public.services FOR SELECT USING (true);
CREATE POLICY "Users can create their own services" ON public.services FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own services" ON public.services FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own services" ON public.services FOR DELETE USING (auth.uid() = user_id);

-- Jobs
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Jobs are readable by everyone" ON public.jobs FOR SELECT USING (true);
CREATE POLICY "Users can create their own jobs" ON public.jobs FOR INSERT WITH CHECK (auth.uid() = client_id);
CREATE POLICY "Users can update their own jobs" ON public.jobs FOR UPDATE USING (auth.uid() = client_id);
CREATE POLICY "Users can delete their own jobs" ON public.jobs FOR DELETE USING (auth.uid() = client_id);

-- Messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own messages" ON public.messages FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can send messages" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reviews are readable by everyone" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users can create reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- Transactions
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own transactions" ON public.transactions FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Locations, Categories, Skills, ID Types, Supported Banks
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.id_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supported_banks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for locations" ON public.locations FOR SELECT USING (true);
CREATE POLICY "Public read access for categories" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Public read access for skills" ON public.skills FOR SELECT USING (true);
CREATE POLICY "Public read access for id_types" ON public.id_types FOR SELECT USING (true);
CREATE POLICY "Public read access for supported_banks" ON public.supported_banks FOR SELECT USING (true);

-- Triggers for Notifications

-- Generic Webhook for Push Notifications
CREATE OR REPLACE FUNCTION public.handle_notification_inserted()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://bvnaffajgxxylatshlwc.supabase.co/functions/v1/push_notifications',
      headers := jsonb_build_object(
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object('record', row_to_json(NEW))
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_notification_inserted
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.handle_notification_inserted();

-- Message Notification Trigger
CREATE OR REPLACE FUNCTION trigger_message_notification() RETURNS TRIGGER AS $$
DECLARE sender_name text;
BEGIN
  SELECT display_name INTO sender_name FROM public.users WHERE id = NEW.sender_id;
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (NEW.receiver_id, 'chat', 'New Message from ' || COALESCE(sender_name, 'User'), NEW.content, jsonb_build_object('sender_id', NEW.sender_id, 'chat_id', NEW.id));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trigger_message_to_notification
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION trigger_message_notification();

-- Order Notification Trigger
CREATE OR REPLACE FUNCTION trigger_order_notification() RETURNS TRIGGER AS $$
DECLARE 
  service_title text;
  buyer_name text;
  seller_name text;
BEGIN
  SELECT title INTO service_title FROM public.services WHERE id = NEW.service_id;
  SELECT display_name INTO buyer_name FROM public.users WHERE id = NEW.buyer_id;
  SELECT display_name INTO seller_name FROM public.users WHERE id = NEW.seller_id;

  IF TG_OP = 'INSERT' THEN
    -- Notify seller of new order
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (NEW.seller_id, 'order', 'New Order Request', COALESCE(buyer_name, 'A user') || ' ordered: ' || COALESCE(service_title, 'a service'), jsonb_build_object('order_id', NEW.id, 'service_id', NEW.service_id));
  ELSIF TG_OP = 'UPDATE' AND NEW.status != OLD.status THEN
    -- Notify buyer of status change
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (NEW.buyer_id, 'order', 'Order ' || INITCAP(NEW.status), COALESCE(seller_name, 'The seller') || ' marked your order for ' || COALESCE(service_title, 'a service') || ' as ' || NEW.status, jsonb_build_object('order_id', NEW.id, 'service_id', NEW.service_id));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trigger_order_to_notification
  AFTER INSERT OR UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION trigger_order_notification();

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages, public.jobs, public.transactions, public.notifications;
