import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { JWT } from "https://esm.sh/google-auth-library@9";

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

    // 1. Parse the incoming database webhook payload
    const { record } = await req.json();
    const { sender_id, receiver_id, content } = record;

    if (!sender_id || !receiver_id) {
      return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400 });
    }

    // 2. Fetch sender details and receiver push token
    const { data: sender } = await supabase.from('users').select('display_name').eq('id', sender_id).single();
    const { data: receiver } = await supabase.from('users').select('push_token').eq('id', receiver_id).single();

    if (!receiver?.push_token) {
      return new Response(JSON.stringify({ message: 'No push token for receiver' }), { status: 200 });
    }

    // 3. Get Google Access Token for FCM V1
    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!);
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });

    const tokenResponse = await jwtClient.getAccessToken();
    const accessToken = tokenResponse.token;

    if (!accessToken) {
      throw new Error('Failed to get Google access token');
    }

    // 4. Send the notification via FCM V1
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
    
    const message = {
      message: {
        token: receiver.push_token,
        notification: {
          title: sender?.display_name || 'New Message',
          body: content,
        },
        data: {
          type: 'chat',
          sender_id: sender_id,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channel_id: 'high_importance_channel',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      },
    };

    const fcmResponse = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(message),
    });

    const fcmResult = await fcmResponse.json();
    console.log('FCM Result:', JSON.stringify(fcmResult));

    return new Response(JSON.stringify({ success: true, result: fcmResult }), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    });
  } catch (error) {
    console.error('Push notification error:', error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    });
  }
};
