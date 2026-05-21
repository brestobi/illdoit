-- Fix review notification trigger to use target_user_id
CREATE OR REPLACE FUNCTION public.trigger_review_notification() RETURNS TRIGGER AS $$
DECLARE
  reviewer_name text;
BEGIN
  SELECT display_name INTO reviewer_name FROM public.users WHERE id = NEW.reviewer_id;
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (NEW.target_user_id, 'review', 'New Review', COALESCE(reviewer_name, 'A user') || ' left you a ' || NEW.rating::text || '-star review.', jsonb_build_object('review_id', NEW.id, 'reviewer_id', NEW.reviewer_id));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
