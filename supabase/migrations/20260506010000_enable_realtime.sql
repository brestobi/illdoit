-- Enable real-time for messages table
alter publication supabase_realtime add table public.messages;

-- Chat Images Bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('chat-images', 'chat-images', true)
ON CONFLICT (id) DO NOTHING;

-- Chat Images Policies
CREATE POLICY "Chat images are accessible by chat participants"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat-images');

CREATE POLICY "Users can upload chat images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'chat-images' AND (storage.foldername(name))[1] = 'chat');
