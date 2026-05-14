-- Create id_types table
CREATE TABLE public.id_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create supported_banks table
CREATE TABLE public.supported_banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE id_types, supported_banks;

-- RLS Policies
ALTER TABLE public.id_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supported_banks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to id_types"
ON public.id_types FOR SELECT TO public USING (true);

CREATE POLICY "Allow public read access to supported_banks"
ON public.supported_banks FOR SELECT TO public USING (true);

-- Insert ID Types
INSERT INTO public.id_types (name) VALUES
('South African ID Smart Card'),
('South African ID Book (Green)'),
('Passport'),
('Driver''s License'),
('Asylum Seeker Document'),
('Work Permit');

-- Insert Supported Banks
INSERT INTO public.supported_banks (name) VALUES
('Absa Bank'),
('Capitec Bank'),
('First National Bank (FNB)'),
('Nedbank'),
('Standard Bank'),
('Investec'),
('African Bank'),
('Bidvest Bank'),
('Discovery Bank'),
('TymeBank'),
('Old Mutual Bank');
