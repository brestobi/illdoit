-- Function to handle successful payment updates
CREATE OR REPLACE FUNCTION public.handle_payment_success()
RETURNS trigger AS $$
BEGIN
  -- Only proceed if the status changed from something else to 'successful'
  IF (NEW.status = 'successful' AND (OLD.status IS NULL OR OLD.status != 'successful')) THEN
    -- Check if a transaction for this payment reference already exists to prevent duplicates
    IF NOT EXISTS (
      SELECT 1 FROM public.transactions 
      WHERE reference = 'Payment Ref: ' || NEW.reference
    ) THEN
      -- Insert the transaction which will automatically trigger the balance update via public.update_user_balances()
      INSERT INTO public.transactions (
        sender_id,
        receiver_id,
        amount,
        type,
        status,
        reference
      ) VALUES (
        NEW.user_id, -- For deposits, sender and receiver can be the same user or a system ID
        NEW.user_id,
        NEW.amount,
        'deposit',
        'completed',
        'Payment Ref: ' || NEW.reference
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to execute the function after a payment record is updated
DROP TRIGGER IF EXISTS on_payment_success ON public.payments;
CREATE TRIGGER on_payment_success
  AFTER UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_payment_success();

-- COMMENT: This trigger ensures that once the Yoco webhook (or any other gateway) 
-- updates a payment status to 'successful', the user's balance is automatically 
-- credited without needing manual transaction insertion in the Edge Function code.
