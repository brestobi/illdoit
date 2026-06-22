-- Function to trigger completion email
CREATE OR REPLACE FUNCTION public.handle_order_completion_email()
RETURNS TRIGGER AS $$
BEGIN
  -- Trigger only when status changes to 'completed'
  IF (NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed')) THEN
    PERFORM
      net.http_post(
        url := 'https://bvnaffajgxxylatshlwc.supabase.co/functions/v1/send_completion_email',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-webhook-secret', current_setting('app.settings.webhook_secret') -- Need to set this in Supabase
        ),
        body := jsonb_build_object('record', row_to_json(NEW))
      );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
DROP TRIGGER IF EXISTS on_order_completed ON public.orders;
CREATE TRIGGER on_order_completed
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_order_completion_email();
