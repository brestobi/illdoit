import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export default async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'content-type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const authHeader = req.headers.get('Authorization')!;
    const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'content-type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    const body = await req.json();
    const amount = Number(body.amount);
    const currency = body.currency || 'ZAR';
    const clientReference = body.reference; // Reference from client
    const description = body.description || 'Wallet top-up';

    if (!amount || amount <= 0) {
      return new Response(JSON.stringify({ error: 'Invalid amount.' }), {
        status: 400,
        headers: { 'content-type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    const secretKey = Deno.env.get('YOCO_SECRET_KEY');
    if (!secretKey) {
      return new Response(JSON.stringify({ error: 'YOCO_SECRET_KEY is not configured.' }), {
        status: 500,
        headers: { 'content-type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    // 1. Create a pending payment record in our database
    const { data: paymentRecord, error: dbError } = await supabase
      .from('payments')
      .insert({
        user_id: user.id,
        amount: amount,
        currency: currency,
        status: 'pending',
        reference: `PAY-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
        metadata: { client_reference: clientReference, description: description }
      })
      .select()
      .single();

    if (dbError) {
      throw new Error(`Database error: ${dbError.message}`);
    }

    // 2. Call Yoco to create checkout session
    const checkoutPayload = {
      amountInCents: Math.round(amount * 100),
      currency,
      reference: paymentRecord.reference, // Use our internal reference
      description,
      metadata: {
        payment_id: paymentRecord.id,
        user_id: user.id
      }
    };

    const yocoResponse = await fetch('https://online.yoco.com/v1/checkout', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(checkoutPayload),
    });

    const yocoData = await yocoResponse.json();
    if (!yocoResponse.ok) {
      // Update record to failed
      await supabase.from('payments').update({ status: 'failed' }).eq('id', paymentRecord.id);
      
      return new Response(JSON.stringify({ error: yocoData }), {
        status: yocoResponse.status,
        headers: { 'content-type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    const checkoutUrl =
      yocoData.checkout_url ||
      yocoData.checkoutUrl ||
      yocoData.redirect_url ||
      yocoData.redirectUrl ||
      yocoData.url ||
      yocoData.paymentUrl;

    // 3. Update record with external ID
    await supabase.from('payments').update({ 
      external_id: yocoData.id || yocoData.checkoutId,
      metadata: { ...paymentRecord.metadata, yoco_data: yocoData }
    }).eq('id', paymentRecord.id);

    return new Response(JSON.stringify({ 
      checkout_url: checkoutUrl ?? null, 
      payment_id: paymentRecord.id,
      reference: paymentRecord.reference
    }), {
      status: 200,
      headers: { 'content-type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), {
      status: 500,
      headers: { 'content-type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  }
};
