import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'content-type': 'application/json' },
    });
  }

  try {
    // TEMPORARY FIX: Verify custom secret header
    const webhookSecret = req.headers.get('x-webhook-secret');
    if (webhookSecret !== Deno.env.get('WEBHOOK_SECRET')) {
       return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }

    const { record } = await req.json();
    const { buyer_id, seller_id, id: order_id } = record;

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Fetch buyer and seller emails
    const { data: buyer } = await supabase.from('users').select('email').eq('id', buyer_id).single();
    const { data: seller } = await supabase.from('users').select('email').eq('id', seller_id).single();

    if (!buyer?.email || !seller?.email) {
      throw new Error('Buyer or seller email not found');
    }

    // Send email using Resend
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "I'll Do It <noreply@illdoit.com>",
        to: [buyer.email, seller.email],
        subject: `Order ${order_id} Completed`,
        html: `<h1>Order Completed</h1><p>Your order ${order_id} has been marked as completed.</p>`,
      }),
    });

    const data = await res.json();
    return new Response(JSON.stringify({ success: true, data }), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    });
  } catch (error) {
    console.error('Email error:', error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    });
  }
});
