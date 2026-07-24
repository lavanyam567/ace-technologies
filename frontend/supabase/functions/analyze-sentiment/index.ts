import { corsHeaders } from "../_shared/cors.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type SentimentBody = {
  review_id: string;
  product_id: string;
  text: string;
};

// HuggingFace distilbert sentiment model (free, fast, no GPU needed)
const HF_MODEL =
  "distilbert-base-uncased-finetuned-sst-2-english";

// Simple keyword extraction from review text
function extractKeywords(text: string, sentiment: string): string[] {
  const positiveWords = [
    "great", "excellent", "good", "best", "amazing", "perfect", "love",
    "awesome", "fantastic", "quality", "fast", "reliable", "worth",
    "recommend", "happy", "satisfied", "nice", "smooth", "durable",
  ];
  const negativeWords = [
    "bad", "poor", "worst", "terrible", "waste", "broken", "cheap",
    "slow", "useless", "disappointed", "awful", "defective", "issue",
    "problem", "fail", "return", "refund", "damage", "error",
  ];

  const words = text.toLowerCase().match(/\b[a-z]{4,}\b/g) ?? [];
  const wordList = sentiment === "positive" ? positiveWords : negativeWords;
  const found = words.filter((w) => wordList.includes(w));
  return [...new Set(found)].slice(0, 5);
}

// Map HuggingFace labels to our sentiment values
function mapLabel(label: string, score: number): string {
  if (label === "POSITIVE" && score >= 0.55) return "positive";
  if (label === "NEGATIVE" && score >= 0.55) return "negative";
  return "neutral";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const hfKey = Deno.env.get("HF_API_KEY");
    if (!hfKey) {
      throw new Error("HuggingFace API key (HF_API_KEY) is not configured.");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Supabase configuration is missing.");
    }

    const body = (await req.json()) as SentimentBody;
    const { review_id, product_id, text } = body;

    if (!review_id || !product_id || !text?.trim()) {
      throw new Error("review_id, product_id, and text are required.");
    }

    // ── Call HuggingFace Inference API ──────────────────────────────
    const hfResponse = await fetch(
      `https://api-inference.huggingface.co/models/${HF_MODEL}`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${hfKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ inputs: text.slice(0, 512) }),
      },
    );

    if (!hfResponse.ok) {
      // Model may be loading (cold start). Fall back to simple scoring.
      const errText = await hfResponse.text();
      console.warn("HuggingFace error, using lexicon fallback:", errText);

      // Lexicon fallback
      const lowerText = text.toLowerCase();
      const posScore = [
        "good", "great", "excellent", "love", "best", "amazing",
      ].filter((w) => lowerText.includes(w)).length;
      const negScore = [
        "bad", "poor", "worst", "terrible", "broken", "issue",
      ].filter((w) => lowerText.includes(w)).length;

      const fallbackSentiment =
        posScore > negScore ? "positive"
        : negScore > posScore ? "negative"
        : "neutral";
      const fallbackScore = 0.6;
      const keywords = extractKeywords(text, fallbackSentiment);

      const supabase = createClient(supabaseUrl, supabaseServiceKey);
      await supabase.from("review_sentiments").upsert({
        review_id,
        product_id,
        sentiment: fallbackSentiment,
        score: fallbackScore,
        keywords,
        processed_at: new Date().toISOString(),
      });

      return new Response(
        JSON.stringify({ sentiment: fallbackSentiment, score: fallbackScore, keywords }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
      );
    }

    // ── Parse HuggingFace response ──────────────────────────────────
    // Response format: [[{label, score}, {label, score}]]
    const hfData = await hfResponse.json();
    const predictions = Array.isArray(hfData[0]) ? hfData[0] : hfData;
    const top = predictions.reduce(
      (best: { label: string; score: number }, cur: { label: string; score: number }) =>
        cur.score > best.score ? cur : best,
      predictions[0],
    );

    const sentiment = mapLabel(top.label as string, top.score as number);
    const score = Math.round((top.score as number) * 1000) / 1000;
    const keywords = extractKeywords(text, sentiment);

    // ── Save to Supabase ────────────────────────────────────────────
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const { error: dbError } = await supabase
      .from("review_sentiments")
      .upsert({
        review_id,
        product_id,
        sentiment,
        score,
        keywords,
        processed_at: new Date().toISOString(),
      });

    if (dbError) {
      console.error("DB upsert error:", dbError.message);
    }

    return new Response(
      JSON.stringify({ sentiment, score, keywords }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
    );
  } catch (error) {
    console.error("analyze-sentiment error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 },
    );
  }
});
