import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export default async (req: Request) => {
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

    if (eventType === 'payment.succeeded' || body.status === 'successful') {
      const externalId = payload.id;
      const amountInCents = payload.amountInCents || (payload.amount * 100);
      const reference = payload.reference;
      const metadata = payload.metadata || {};
      const paymentId = metadata.payment_id;
      const userId = metadata.user_id;

      if (!paymentId || !userId) {
        console.error('Missing payment_id or user_id in metadata');
        return new Response(JSON.stringify({ error: 'Missing metadata' }), { status: 400 });
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
      await supabase
        .from('payments')
        .update({ 
          status: 'successful', 
          external_id: externalId,
          updated_at: new Date().toISOString()
        })
        .eq('id', paymentId);

      // 3. Create a transaction record (this updates the user's viewable balance)
      const { error: txError } = await supabase
        .from('transactions')
        .insert({
          sender_id: userId,
          receiver_id: userId,
          amount: amountInCents / 100,
          type: 'deposit',
          status: 'completed',
          reference: `Yoco: ${reference}`
        });

      if (txError) {
        console.error('Failed to create transaction:', txError);
        // We don't return error to Yoco here because we want them to stop retrying if the payment was actually successful
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
