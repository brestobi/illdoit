-- Trigger to update user balances based on transactions
CREATE OR REPLACE FUNCTION public.update_user_balances()
RETURNS trigger AS $$
BEGIN
  -- Handle DEPOSIT
  IF (NEW.type = 'deposit' AND NEW.status = 'completed') THEN
    UPDATE public.users SET balance = balance + NEW.amount WHERE id = NEW.receiver_id;
  
  -- Handle WITHDRAWAL
  ELSIF (NEW.type = 'withdrawal' AND NEW.status = 'completed') THEN
    UPDATE public.users SET balance = balance - NEW.amount WHERE id = NEW.sender_id;
    
  -- Handle ESCROW (Lock funds)
  ELSIF (NEW.type = 'escrow' AND NEW.status = 'pending') THEN
    UPDATE public.users SET balance = balance - NEW.amount, escrow_balance = escrow_balance + NEW.amount WHERE id = NEW.sender_id;
    -- For the receiver, we just show it's in escrow (optional: add to their escrow_balance view)
    UPDATE public.users SET escrow_balance = escrow_balance + NEW.amount WHERE id = NEW.receiver_id;

  -- Handle ESCROW RELEASE (Move from escrow to receiver balance)
  ELSIF (NEW.type = 'escrow_release' AND NEW.status = 'completed') THEN
    -- Deduct from sender's escrow
    UPDATE public.users SET escrow_balance = escrow_balance - NEW.amount WHERE id = NEW.sender_id;
    -- Move to receiver's available balance and deduct from their escrow view
    UPDATE public.users SET balance = balance + NEW.amount, escrow_balance = escrow_balance - NEW.amount WHERE id = NEW.receiver_id;

  -- Handle ESCROW REFUND / CANCEL
  ELSIF (NEW.status = 'cancelled' AND OLD.status = 'pending' AND OLD.type = 'escrow') THEN
    UPDATE public.users SET balance = balance + OLD.amount, escrow_balance = escrow_balance - OLD.amount WHERE id = OLD.sender_id;
    UPDATE public.users SET escrow_balance = escrow_balance - OLD.amount WHERE id = OLD.receiver_id;

  -- Handle DIRECT PAYMENT
  ELSIF (NEW.type = 'payment' AND NEW.status = 'completed') THEN
    UPDATE public.users SET balance = balance - NEW.amount WHERE id = NEW.sender_id;
    UPDATE public.users SET balance = balance + NEW.amount WHERE id = NEW.receiver_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for INSERT
DROP TRIGGER IF EXISTS on_transaction_inserted ON public.transactions;
CREATE TRIGGER on_transaction_inserted
  AFTER INSERT ON public.transactions
  FOR EACH ROW EXECUTE PROCEDURE public.update_user_balances();

-- Trigger for UPDATE (to handle status changes like escrow release or cancellation)
DROP TRIGGER IF EXISTS on_transaction_updated ON public.transactions;
CREATE TRIGGER on_transaction_updated
  AFTER UPDATE ON public.transactions
  FOR EACH ROW EXECUTE PROCEDURE public.update_user_balances();
