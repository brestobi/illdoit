-- Create report_reasons table
CREATE TABLE public.report_reasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create dispute_reasons table
CREATE TABLE public.dispute_reasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE report_reasons, dispute_reasons;

-- RLS Policies
ALTER TABLE public.report_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispute_reasons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to report_reasons"
ON public.report_reasons FOR SELECT TO public USING (true);

CREATE POLICY "Allow public read access to dispute_reasons"
ON public.dispute_reasons FOR SELECT TO public USING (true);

-- Insert Report Reasons
INSERT INTO public.report_reasons (name) VALUES
('Scam or Fraud'),
('Abusive Behavior'),
('Inappropriate Content'),
('Late / No-show for job'),
('Poor quality of work'),
('Spam'),
('Harassment'),
('Off-platform payment request'),
('Other');

-- Insert Dispute Reasons
INSERT INTO public.dispute_reasons (name) VALUES
('Service not delivered'),
('Work not as described'),
('Poor quality of work'),
('Seller stopped communicating'),
('Unauthorized extra charges'),
('Incomplete service'),
('Other');
