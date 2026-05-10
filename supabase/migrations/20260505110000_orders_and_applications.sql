-- Orders and Job Applications Migration

-- Orders Table
CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Orders Policies
CREATE POLICY "Users can view their own orders" 
ON public.orders FOR SELECT 
USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Buyers can create orders" 
ON public.orders FOR INSERT 
WITH CHECK (auth.uid() = buyer_id);

CREATE POLICY "Users can update their own orders" 
ON public.orders FOR UPDATE 
USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Job Applications Table
CREATE TABLE public.job_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  applicant_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  cover_letter TEXT,
  bid_amount DECIMAL(10,2),
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(job_id, applicant_id) -- Prevent duplicate applications
);

-- Enable RLS on job applications
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

-- Job Applications Policies
CREATE POLICY "Applicants can view their own applications" 
ON public.job_applications FOR SELECT 
USING (auth.uid() = applicant_id);

CREATE POLICY "Job owners can view applications for their jobs" 
ON public.job_applications FOR SELECT 
USING (auth.uid() IN (SELECT client_id FROM public.jobs WHERE id = job_id));

CREATE POLICY "Users can apply for jobs" 
ON public.job_applications FOR INSERT 
WITH CHECK (auth.uid() = applicant_id);

CREATE POLICY "Users can update their own applications" 
ON public.job_applications FOR UPDATE 
USING (auth.uid() = applicant_id OR auth.uid() IN (SELECT client_id FROM public.jobs WHERE id = job_id));
