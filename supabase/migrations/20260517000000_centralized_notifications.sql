-- 1. Create Notifications Table
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

-- 2. Generic Webhook for Push Notifications
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

CREATE TRIGGER on_notification_inserted
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.handle_notification_inserted();

-- 3. Drop Old Trigger
DROP TRIGGER IF EXISTS on_message_inserted ON public.messages;

-- 4. Event Triggers
-- A. Messages
CREATE OR REPLACE FUNCTION trigger_message_notification() RETURNS TRIGGER AS $$
DECLARE sender_name text;
BEGIN
  SELECT display_name INTO sender_name FROM public.users WHERE id = NEW.sender_id;
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (NEW.receiver_id, 'chat', 'New Message from ' || COALESCE(sender_name, 'User'), NEW.content, jsonb_build_object('sender_id', NEW.sender_id, 'chat_id', NEW.id));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_message_to_notification
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION trigger_message_notification();

-- B. Orders
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

CREATE TRIGGER trigger_order_to_notification
  AFTER INSERT OR UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION trigger_order_notification();

-- C. Job Applications
CREATE OR REPLACE FUNCTION trigger_job_application_notification() RETURNS TRIGGER AS $$
DECLARE 
  job_title text;
  client_id_var UUID;
  applicant_name text;
  client_name text;
BEGIN
  SELECT title, client_id INTO job_title, client_id_var FROM public.jobs WHERE id = NEW.job_id;
  SELECT display_name INTO applicant_name FROM public.users WHERE id = NEW.applicant_id;
  SELECT display_name INTO client_name FROM public.users WHERE id = client_id_var;

  IF TG_OP = 'INSERT' THEN
    -- Notify client
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (client_id_var, 'job_application', 'New Application', COALESCE(applicant_name, 'A user') || ' applied to: ' || COALESCE(job_title, 'your job'), jsonb_build_object('job_id', NEW.job_id, 'application_id', NEW.id));
  ELSIF TG_OP = 'UPDATE' AND NEW.status != OLD.status THEN
    -- Notify applicant
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (NEW.applicant_id, 'job_application', 'Application ' || INITCAP(NEW.status), COALESCE(client_name, 'The client') || ' ' || NEW.status || ' your application for ' || COALESCE(job_title, 'a job'), jsonb_build_object('job_id', NEW.job_id, 'application_id', NEW.id));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_job_application_to_notification
  AFTER INSERT OR UPDATE ON public.job_applications
  FOR EACH ROW EXECUTE FUNCTION trigger_job_application_notification();

-- D. Payments
CREATE OR REPLACE FUNCTION trigger_payment_notification() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.status = 'successful' AND OLD.status != 'successful' THEN
    -- Notify user
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (NEW.user_id, 'payment', 'Payment Successful', 'Your payment of R' || NEW.amount::text || ' was successful.', jsonb_build_object('payment_id', NEW.id));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_payment_to_notification
  AFTER UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION trigger_payment_notification();

-- E. Reviews
CREATE OR REPLACE FUNCTION trigger_review_notification() RETURNS TRIGGER AS $$
DECLARE
  reviewer_name text;
BEGIN
  SELECT display_name INTO reviewer_name FROM public.users WHERE id = NEW.reviewer_id;
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (NEW.reviewee_id, 'review', 'New Review', COALESCE(reviewer_name, 'A user') || ' left you a ' || NEW.rating::text || '-star review.', jsonb_build_object('review_id', NEW.id, 'reviewer_id', NEW.reviewer_id));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_review_to_notification
  AFTER INSERT ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION trigger_review_notification();
