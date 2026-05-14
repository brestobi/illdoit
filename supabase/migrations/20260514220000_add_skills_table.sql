-- Create skills table
CREATE TABLE public.skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE skills;

-- RLS Policies
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to skills"
ON public.skills FOR SELECT
TO public
USING (true);

-- Insert Sample Skills
INSERT INTO public.skills (name) VALUES
('Plumbing'),
('Electrical'),
('Carpentry'),
('Cleaning'),
('Gardening'),
('Painting'),
('Graphic Design'),
('Web Development'),
('Writing'),
('Tutoring'),
('Handyman'),
('Delivery'),
('Mobile App Dev'),
('Video Editing'),
('Social Media Management'),
('Data Entry'),
('Virtual Assistant'),
('Translation'),
('Photography'),
('Event Planning'),
('Makeup Artist'),
('Hairdressing'),
('Tailoring'),
('Auto Repair'),
('Personal Training'),
('Yoga Instruction'),
('Catering'),
('Babysitting');
