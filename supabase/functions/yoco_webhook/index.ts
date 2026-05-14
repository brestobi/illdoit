import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export default async (req: Request) => {
  // Handle GET requests for redirects from Yoco
  if (req.method === 'GET') {
    const url = new URL(req.url);
    const action = url.searchParams.get('action');
    
    if (action === 'success') {
      return new Response('<html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>body{font-family:sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0;text-align:center;background:#f5f5f5}h1{color:#4CAF50}.btn{margin-top:20px;padding:12px 24px;background:#2196F3;color:white;text-decoration:none;border-radius:8px}</style></head><body><h1>Payment Successful!</h1><p>Your payment has been processed.</p><p>You can now return to the app.</p></body></html>', {
        headers: { 'content-type': 'text/html' }
      });
    } else if (action === 'cancel') {
      return new Response('<html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>body{font-family:sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0;text-align:center;background:#f5f5f5}h1{color:#f44336}</style></head><body><h1>Payment Cancelled</h1><p>You can close this window and try again.</p></body></html>', {
        headers: { 'content-type': 'text/html' }
      });
    }
    return new Response('Method not allowed', { status: 405 });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'content-type': 'application/json' },
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body = await req.json();
    console.log('Yoco Webhook received:', JSON.stringify(body));

    // Yoco webhooks can have different formats depending on version, 
    // but typically they have a 'type' and a 'payload'.
    const eventType = body.type;
    const payload = body.payload || body;

    if (eventType === 'payment.succeeded' || eventType === 'checkout.paid' || body.status === 'successful' || payload.status === 'successful') {
      const externalId = payload.id;
      const reference = payload.reference;
      const metadata = payload.metadata || {};
      let paymentId = metadata.payment_id;
      let userId = metadata.user_id;

      // Fallback: Find payment by reference if metadata is missing
      if (!paymentId && reference) {
        console.log('Missing payment_id in metadata, searching by reference:', reference);
        const { data: p } = await supabase
          .from('payments')
          .select('id, user_id')
          .eq('reference', reference)
          .single();
        
        if (p) {
          paymentId = p.id;
          userId = p.user_id;
        }
      }

      if (!paymentId) {
        console.error('Could not identify payment record for reference:', reference);
        return new Response(JSON.stringify({ error: 'Missing metadata and record not found' }), { status: 400 });
      }

      // 1. Check if we've already processed this payment to avoid double deposits
      const { data: existingPayment } = await supabase
        .from('payments')
        .select('status')
        .eq('id', paymentId)
        .single();

      if (existingPayment?.status === 'successful') {
        return new Response(JSON.stringify({ message: 'Already processed' }), { status: 200 });
      }

      // 2. Update payment record
      // The 'on_payment_success' database trigger will automatically 
      // create a transaction and update the user's balance.
      const { error: updateError } = await supabase
        .from('payments')
        .update({ 
          status: 'successful', 
          external_id: externalId,
          updated_at: new Date().toISOString()
        })
        .eq('id', paymentId);

      if (updateError) {
        console.error('Failed to update payment status:', updateError);
        return new Response(JSON.stringify({ error: 'Database update failed' }), { status: 500 });
      }

      return new Response(JSON.stringify({ success: true }), { status: 200 });
    }

    return new Response(JSON.stringify({ message: 'Event ignored' }), { status: 200 });
  } catch (error) {
    console.error('Webhook error:', error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    });
  }
};
