-- Create categories table
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('digital', 'physical', 'both')),
    icon TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE categories;

-- RLS Policies
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to categories"
ON public.categories FOR SELECT
TO public
USING (true);

-- Insert Job Categories
INSERT INTO public.categories (name, type) VALUES
-- Digital
('Logo Design', 'digital'),
('Web Development', 'digital'),
('Mobile App Dev', 'digital'),
('Social Media Management', 'digital'),
('Content Writing', 'digital'),
('Copywriting', 'digital'),
('Video Editing', 'digital'),
('Graphic Design', 'digital'),
('SEO Services', 'digital'),
('Data Entry', 'digital'),
('Virtual Assistant', 'digital'),
('Translation', 'digital'),
('Voice Over', 'digital'),
('Digital Marketing', 'digital'),
('UI/UX Design', 'digital'),
('Illustration', 'digital'),
('Software Testing', 'digital'),
('Cybersecurity', 'digital'),
('Blockchain Dev', 'digital'),
('AI/Machine Learning', 'digital'),

-- Physical
('Plumbing', 'physical'),
('Electrical Work', 'physical'),
('Carpentry', 'physical'),
('Painting', 'physical'),
('Cleaning Services', 'physical'),
('Gardening & Landscaping', 'physical'),
('Handyman', 'physical'),
('Auto Repair', 'physical'),
('Delivery & Courier', 'physical'),
('Moving & Hauling', 'physical'),
('Personal Training', 'physical'),
('Hairdressing', 'physical'),
('Makeup Artist', 'physical'),
('Catering', 'physical'),
('Photography', 'physical'),
('Tutor (In-person)', 'physical'),
('Babysitting', 'physical'),
('Pet Sitting/Walking', 'physical'),
('Security Services', 'physical'),
('Event Planning', 'physical'),
('Construction', 'physical'),
('Roofing', 'physical'),
('Tiling', 'physical'),
('Welding', 'physical'),
('Laundry Services', 'physical'),
('Tailoring', 'physical'),
('Massage Therapy', 'physical'),
('Yoga Instruction', 'physical');
