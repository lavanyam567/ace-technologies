import { corsHeaders } from "../_shared/cors.ts";

type RazorpayWebhookEvent = {
  event?: string;
  payload?: {
    payment?: {
      entity?: {
        id?: string;
        status?: string;
        order_id?: string;
      };
    };
  };
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET");
    if (!webhookSecret) {
      throw new Error("Razorpay webhook secret is not configured.");
    }

    const signature = req.headers.get("x-razorpay-signature");
    if (!signature) {
      throw new Error("Missing Razorpay webhook signature.");
    }

    const rawBody = await req.text();
    const expectedSignature = await hmacSha256(webhookSecret, rawBody);
    if (!timingSafeEqual(expectedSignature, signature)) {
      throw new Error("Invalid Razorpay webhook signature.");
    }

    const event = JSON.parse(rawBody) as RazorpayWebhookEvent;
    const payment = event.payload?.payment?.entity;

    return new Response(
      JSON.stringify({
        received: true,
        event: event.event,
        payment_id: payment?.id,
        payment_status: payment?.status,
        razorpay_order_id: payment?.order_id,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      },
    );
  }
});

async function hmacSha256(secret: string, message: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(message),
  );
  return Array.from(new Uint8Array(signature))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let index = 0; index < a.length; index += 1) {
    result |= a.charCodeAt(index) ^ b.charCodeAt(index);
  }
  return result === 0;
}
