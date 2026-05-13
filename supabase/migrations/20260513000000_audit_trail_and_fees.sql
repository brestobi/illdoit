-- Improvements for Audit Trail and Platform Fees

-- 1. Add fee column to orders and transactions
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS fee DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS fee DECIMAL(10,2) DEFAULT 0;

-- 2. Update the balance trigger to be more robust
CREATE OR REPLACE FUNCTION public.update_user_balances()
RETURNS trigger AS $$
BEGIN
  -- Handle DEPOSIT
  IF (NEW.type = 'deposit' AND NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed')) THEN
    UPDATE public.users SET balance = balance + NEW.amount WHERE id = NEW.receiver_id;
  
  -- Handle WITHDRAWAL (Initial Lock)
  ELSIF (NEW.type = 'withdrawal' AND NEW.status = 'pending' AND OLD.status IS NULL) THEN
    -- Lock funds: remove from balance, move to escrow_balance
    UPDATE public.users SET balance = balance - NEW.amount, escrow_balance = escrow_balance + NEW.amount WHERE id = NEW.sender_id;

  -- Handle WITHDRAWAL (Finalized/Completed)
  ELSIF (NEW.type = 'withdrawal' AND NEW.status = 'completed' AND OLD.status = 'pending') THEN
    -- Finalize: remove from escrow_balance (it was already removed from balance)
    UPDATE public.users SET escrow_balance = escrow_balance - NEW.amount WHERE id = NEW.sender_id;

  -- Handle WITHDRAWAL (Cancelled/Rejected)
  ELSIF (NEW.type = 'withdrawal' AND NEW.status = 'cancelled' AND OLD.status = 'pending') THEN
    -- Return funds: remove from escrow_balance, move back to balance
    UPDATE public.users SET balance = balance + NEW.amount, escrow_balance = escrow_balance - NEW.amount WHERE id = NEW.sender_id;
    
  -- Handle ESCROW (Lock funds for Orders/Jobs)
  ELSIF (NEW.type = 'escrow' AND NEW.status = 'pending' AND OLD.status IS NULL) THEN
    -- Deduct from buyer balance, move to buyer escrow
    UPDATE public.users SET balance = balance - NEW.amount, escrow_balance = escrow_balance + NEW.amount WHERE id = NEW.sender_id;
    -- Show as pending escrow for the seller/worker
    UPDATE public.users SET escrow_balance = escrow_balance + NEW.amount WHERE id = NEW.receiver_id;

  -- Handle ESCROW RELEASE (Move from escrow to receiver balance, minus fees)
  ELSIF (NEW.type = 'escrow_release' AND NEW.status = 'completed' AND OLD.status = 'pending') THEN
    -- Deduct from buyer's escrow
    UPDATE public.users SET escrow_balance = escrow_balance - NEW.amount WHERE id = NEW.sender_id;
    -- Move NET amount (amount - fee) to receiver's available balance and deduct from their escrow view
    UPDATE public.users 
    SET balance = balance + (NEW.amount - NEW.fee), 
        escrow_balance = escrow_balance - NEW.amount 
    WHERE id = NEW.receiver_id;

  -- Handle ESCROW REFUND / CANCEL
  ELSIF (NEW.status = 'cancelled' AND OLD.status = 'pending' AND OLD.type = 'escrow') THEN
    -- Return full amount to buyer balance
    UPDATE public.users SET balance = balance + OLD.amount, escrow_balance = escrow_balance - OLD.amount WHERE id = OLD.sender_id;
    -- Remove from worker's escrow view
    UPDATE public.users SET escrow_balance = escrow_balance - OLD.amount WHERE id = OLD.receiver_id;

  -- Handle DIRECT PAYMENT
  ELSIF (NEW.type = 'payment' AND NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed')) THEN
    UPDATE public.users SET balance = balance - NEW.amount WHERE id = NEW.sender_id;
    UPDATE public.users SET balance = balance + NEW.amount WHERE id = NEW.receiver_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: The triggers are already attached to public.transactions from the previous migration.
-- They will now use this updated function logic.
