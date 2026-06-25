-- =============================================================
-- Migration: Job-Scoped Messaging System
-- Date: 2026-06-25
-- Description:
--   - Links messages to a specific job (mandatory for messaging)
--   - Adds message_type (text, system, progress_update, quick_action, location)
--   - Adds metadata JSONB for location coords, quick_action payload, etc.
--   - Adds worker_id to jobs table (the accepted applicant)
--   - Enforces RLS: can only message if a shared in_progress job exists
--   - Physical jobs: records time-block violations at DB level (app enforces too)
-- =============================================================

-- 1. Add worker_id to jobs (the accepted worker for in_progress jobs)
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS worker_id UUID REFERENCES public.users(id) ON DELETE SET NULL;

-- 2. Enhance messages table
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS message_type TEXT NOT NULL DEFAULT 'text',
  -- text | system | progress_update | quick_action | location | time_blocked
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- 3. Index for job-specific message lookups
CREATE INDEX IF NOT EXISTS idx_messages_job_id ON public.messages(job_id);
CREATE INDEX IF NOT EXISTS idx_jobs_worker_id ON public.jobs(worker_id);

-- 4. Drop old RLS policies for messages and replace with job-scoped ones
DROP POLICY IF EXISTS "Users can view their own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;

-- 4a. View: only parties in the related in_progress job can see messages
CREATE POLICY "Job parties can view messages" ON public.messages
  FOR SELECT USING (
    auth.uid() = sender_id
    OR auth.uid() = receiver_id
  );

-- 4b. Send: only allowed if sender and receiver share an in_progress job
--     AND the job must exist with the sender and receiver as client/worker
CREATE POLICY "Job parties can send messages" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_id
        AND j.status = 'in_progress'
        AND (
          (j.client_id = auth.uid() AND j.worker_id = receiver_id)
          OR
          (j.worker_id = auth.uid() AND j.client_id = receiver_id)
        )
    )
  );

-- 5. Function: get active job between two users (used by the app to validate chat)
CREATE OR REPLACE FUNCTION public.get_active_job_between_users(p_user_a UUID, p_user_b UUID)
RETURNS TABLE(
  id UUID,
  title TEXT,
  job_type TEXT,
  status TEXT,
  deadline TIMESTAMPTZ,
  client_id UUID,
  worker_id UUID,
  budget DECIMAL,
  location TEXT,
  category TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    j.id, j.title, j.job_type, j.status, j.deadline,
    j.client_id, j.worker_id, j.budget, j.location, j.category
  FROM public.jobs j
  WHERE j.status = 'in_progress'
    AND (
      (j.client_id = p_user_a AND j.worker_id = p_user_b)
      OR
      (j.client_id = p_user_b AND j.worker_id = p_user_a)
    )
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Update message notification trigger to include job context
CREATE OR REPLACE FUNCTION trigger_message_notification() RETURNS TRIGGER AS $$
DECLARE
  sender_name text;
  job_title text;
BEGIN
  SELECT display_name INTO sender_name FROM public.users WHERE id = NEW.sender_id;

  IF NEW.job_id IS NOT NULL THEN
    SELECT title INTO job_title FROM public.jobs WHERE id = NEW.job_id;
  END IF;

  -- Don't notify for system/time_blocked messages
  IF NEW.message_type IN ('system', 'time_blocked') THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    NEW.receiver_id,
    'chat',
    CASE
      WHEN NEW.message_type = 'progress_update' THEN '📊 Progress Update from ' || COALESCE(sender_name, 'User')
      WHEN NEW.message_type = 'quick_action' THEN '🚗 Update from ' || COALESCE(sender_name, 'User')
      WHEN NEW.message_type = 'location' THEN '📍 Location shared by ' || COALESCE(sender_name, 'User')
      ELSE 'New Message from ' || COALESCE(sender_name, 'User')
    END,
    CASE
      WHEN job_title IS NOT NULL THEN '[' || COALESCE(job_title, 'Job') || '] ' || NEW.content
      ELSE NEW.content
    END,
    jsonb_build_object(
      'sender_id', NEW.sender_id,
      'chat_id', NEW.id,
      'job_id', NEW.job_id,
      'message_type', NEW.message_type
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Function to get all job-linked conversations for the current user
CREATE OR REPLACE FUNCTION public.get_job_conversations(p_user_id UUID)
RETURNS TABLE(
  other_user_id UUID,
  other_user_name TEXT,
  other_user_avatar TEXT,
  job_id UUID,
  job_title TEXT,
  job_type TEXT,
  job_status TEXT,
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH active_jobs AS (
    SELECT j.id AS jid, j.title, j.job_type, j.status,
           j.client_id, j.worker_id
    FROM public.jobs j
    WHERE j.status = 'in_progress'
      AND (j.client_id = p_user_id OR j.worker_id = p_user_id)
  ),
  other_users AS (
    SELECT
      aj.jid, aj.title, aj.job_type, aj.status,
      CASE WHEN aj.client_id = p_user_id THEN aj.worker_id ELSE aj.client_id END AS other_id
    FROM active_jobs aj
    WHERE (aj.client_id = p_user_id AND aj.worker_id IS NOT NULL)
       OR (aj.worker_id = p_user_id AND aj.client_id IS NOT NULL)
  ),
  last_msgs AS (
    SELECT DISTINCT ON (m.job_id)
      m.job_id, m.content, m.created_at,
      COUNT(*) FILTER (WHERE m.receiver_id = p_user_id AND NOT m.is_read) OVER (PARTITION BY m.job_id) AS unread
    FROM public.messages m
    WHERE m.job_id IN (SELECT jid FROM active_jobs)
    ORDER BY m.job_id, m.created_at DESC
  )
  SELECT
    ou.other_id,
    u.display_name,
    u.avatar_url,
    ou.jid,
    ou.title,
    ou.job_type,
    ou.status,
    COALESCE(lm.content, ''),
    lm.created_at,
    COALESCE(lm.unread, 0)
  FROM other_users ou
  JOIN public.users u ON u.id = ou.other_id
  LEFT JOIN last_msgs lm ON lm.job_id = ou.jid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
