import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "content-type": "application/json" },
    });
  }

  try {
    const webhookSecret = req.headers.get("x-webhook-secret");
    if (webhookSecret !== Deno.env.get("WEBHOOK_SECRET")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    const { type, table, record, old_record } = await req.json();

    // Only process UPDATE events on user_reports
    if (type !== "UPDATE" || table !== "user_reports") {
      return new Response(
        JSON.stringify({ message: "Not a user_reports update event" }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    }

    const { id, reporter_id, reason, status, admin_notes } = record;

    // Only send email when status changes from pending to reviewed/dismissed
    if (
      !id || !reporter_id || !status ||
      old_record?.status !== "pending" ||
      (status !== "reviewed" && status !== "dismissed")
    ) {
      return new Response(
        JSON.stringify({ message: "No email needed for this status change" }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get reporter details
    const { data: reporter, error: userError } = await supabase
      .from("users")
      .select("email, display_name")
      .eq("id", reporter_id)
      .single();

    if (userError || !reporter?.email) {
      console.error("Reporter not found:", userError);
      return new Response(
        JSON.stringify({ error: "Reporter not found or email missing" }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    }

    const isReviewed = status === "reviewed";
    const subject = isReviewed
      ? "Your report has been reviewed — action taken"
      : "Your report has been reviewed — no action taken";

    const html = `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f3f4f6; margin: 0; padding: 0;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background: #f3f4f6; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0" style="background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08);">
          <tr>
            <td style="background: linear-gradient(135deg, ${
              isReviewed ? "#059669, #10b981" : "#6b7280, #9ca3af"
            }); padding: 40px 32px; text-align: center;">
              <h1 style="color: #ffffff; font-size: 28px; margin: 0;">
                ${isReviewed ? "✅" : "ℹ️"} Report Update
              </h1>
            </td>
          </tr>
          <tr>
            <td style="padding: 32px;">
              <p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 16px;">
                Hi <strong>${reporter.display_name || "there"}</strong>,
              </p>
              <p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 16px;">
                Thank you for submitting a report regarding: <strong>"${reason}"</strong>
              </p>
              ${
                isReviewed
                  ? `<p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 16px;">
                      We have carefully reviewed your report and
                      <strong style="color: #059669;">appropriate action has been taken</strong>.
                      Your report helps keep our community safe.
                    </p>`
                  : `<p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 16px;">
                      After careful review, we have decided
                      <strong style="color: #6b7280;">not to take action</strong>
                      regarding your report at this time.
                    </p>`
              }
              ${
                admin_notes
                  ? `<p style="color: #374151; font-size: 15px; line-height: 1.6; margin: 0 0 16px; padding: 12px; background: #f9fafb; border-radius: 8px;">
                      <strong>Admin notes:</strong><br/>${admin_notes}
                    </p>`
                  : ""
              }
              <p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0;">
                Thanks,<br/>
                <strong style="color: #059669;">IllDOIT SPACE Team</strong>
              </p>
            </td>
          </tr>
          <tr>
            <td style="background: #f9fafb; padding: 20px 32px; text-align: center;">
              <p style="color: #9ca3af; font-size: 13px; margin: 0;">
                &copy; 2026 I'll Do It. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "IllDOIT SPACE <noreply@updates.illdoit.space>",
        to: [reporter.email],
        subject,
        html,
      }),
    });

    const data = await res.json();
    return new Response(JSON.stringify({ success: true, data }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  } catch (error) {
    console.error("Email error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { "content-type": "application/json" } },
    );
  }
});
