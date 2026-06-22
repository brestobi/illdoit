-- Enable the pg_net extension to allow HTTP requests from the database
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create the trigger function to call the Edge Function
CREATE OR REPLACE FUNCTION public.handle_new_message_notification()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://bvnaffajgxxylatshlwc.supabase.co/functions/v1/push_notifications',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-webhook-secret', 'my-very-secret-password-12345'
      ),
      body := jsonb_build_object('record', row_to_json(NEW))
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add the trigger to the messages table
DROP TRIGGER IF EXISTS on_message_inserted ON public.messages;
CREATE TRIGGER on_message_inserted
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_message_notification();
