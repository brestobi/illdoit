-- Create atomic function to accept job and hold funds in escrow
CREATE OR REPLACE FUNCTION public.accept_job_escrow(p_application_id UUID)
RETURNS VOID AS $$
DECLARE
    v_app RECORD;
    v_job RECORD;
    v_client_balance DECIMAL;
    v_amount DECIMAL;
    v_order_id UUID;
BEGIN
    -- 1. Get Application
    SELECT * INTO v_app FROM public.job_applications WHERE id = p_application_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Application not found'; END IF;

    -- 2. Get Job
    SELECT * INTO v_job FROM public.jobs WHERE id = v_app.job_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Job not found'; END IF;
    IF v_job.status != 'open' THEN RAISE EXCEPTION 'Job is not open'; END IF;

    -- 3. Calculate amount
    v_amount := COALESCE(v_app.bid_amount, v_job.budget);

    -- 4. Check Balance
    SELECT balance INTO v_client_balance FROM public.users WHERE id = v_job.client_id;
    IF v_client_balance < v_amount THEN RAISE EXCEPTION 'Insufficient funds'; END IF;

    -- 5. Create Order
    INSERT INTO public.orders (buyer_id, seller_id, job_id, amount, status)
    VALUES (v_job.client_id, v_app.applicant_id, v_job.id, v_amount, 'in_progress')
    RETURNING id INTO v_order_id;

    -- 6. Create Transaction (This will trigger balance update)
    INSERT INTO public.transactions (sender_id, receiver_id, amount, type, status, order_id)
    VALUES (v_job.client_id, v_app.applicant_id, v_amount, 'escrow', 'pending', v_order_id);

    -- 7. Update Job Status
    UPDATE public.jobs SET status = 'in_progress' WHERE id = v_job.id;

    -- 8. Update Application Status
    UPDATE public.job_applications SET status = 'accepted' WHERE id = p_application_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
