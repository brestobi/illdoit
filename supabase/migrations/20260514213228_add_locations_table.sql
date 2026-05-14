-- Create locations table
CREATE TABLE public.locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    province TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE locations;

-- RLS Policies
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to locations"
ON public.locations FOR SELECT
TO public
USING (true);

-- Insert South African Cities/Towns
INSERT INTO public.locations (name, province) VALUES
('Johannesburg', 'Gauteng'),
('Soweto', 'Gauteng'),
('Pretoria', 'Gauteng'),
('Sandton', 'Gauteng'),
('Centurion', 'Gauteng'),
('Cape Town', 'Western Cape'),
('Stellenbosch', 'Western Cape'),
('Paarl', 'Western Cape'),
('George', 'Western Cape'),
('Knysna', 'Western Cape'),
('Durban', 'KwaZulu-Natal'),
('Pietermaritzburg', 'KwaZulu-Natal'),
('Umhlanga', 'KwaZulu-Natal'),
('Richards Bay', 'KwaZulu-Natal'),
('Port Elizabeth', 'Eastern Cape'),
('East London', 'Eastern Cape'),
('Grahamstown', 'Eastern Cape'),
('Mthatha', 'Eastern Cape'),
('Bloemfontein', 'Free State'),
('Welkom', 'Free State'),
('Sasolburg', 'Free State'),
('Polokwane', 'Limpopo'),
('Tzaneen', 'Limpopo'),
('Thohoyandou', 'Limpopo'),
('Nelspruit', 'Mpumalanga'),
('Witbank', 'Mpumalanga'),
('Secunda', 'Mpumalanga'),
('Rustenburg', 'North West'),
('Potchefstroom', 'North West'),
('Klerksdorp', 'North West'),
('Kimberley', 'Northern Cape'),
('Upington', 'Northern Cape');
