import { corsHeaders } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";

type CreateOrderBody = {
  amount?: number;
  currency?: string;
  payment_method?: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    await requireUser(req);

    const keyId = Deno.env.get("RAZORPAY_KEY_ID");
    const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET");
    if (!keyId || !keySecret) {
      throw new Error("Razorpay credentials are not configured.");
    }

    const body = (await req.json()) as CreateOrderBody;
    const amount = Number(body.amount ?? 0);
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new Error("Invalid payment amount.");
    }

    const amountInPaise = Math.round(amount * 100);
    const currency = body.currency ?? "INR";
    const receipt = `ace_${crypto.randomUUID()}`;

    const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${keyId}:${keySecret}`)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amountInPaise,
        currency,
        receipt,
        notes: {
          payment_method: body.payment_method ?? "online",
          app: "ace_technologies",
        },
      }),
    });

    const data = await razorpayResponse.json();
    if (!razorpayResponse.ok) {
      throw new Error(data?.error?.description ?? "Razorpay order failed.");
    }

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
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
