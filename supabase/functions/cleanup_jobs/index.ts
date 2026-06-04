import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Initialize client
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

Deno.serve(async (req) => {
  // 1. Authenticate request (basic check, ensure this is only called by Supabase Cron)
  const authHeader = req.headers.get('Authorization');
  if (authHeader !== `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  // 2. Delete expired jobs
  // Note: Ensure your database has ON DELETE CASCADE on foreign keys
  // in tables that reference the 'jobs' table.
  const { error } = await supabase
    .from('jobs')
    .delete()
    .lt('deadline', new Date().toISOString())
    .eq('status', 'open');

  if (error) {
    console.error('Error cleaning up jobs:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ message: 'Expired jobs cleaned successfully' }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
});
