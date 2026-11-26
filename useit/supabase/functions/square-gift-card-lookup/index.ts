const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  let requestBody: unknown;
  try {
    requestBody = await request.json();
  } catch {
    return jsonResponse({ error: "Request body must be valid JSON." }, 400);
  }

  const gan = (requestBody as { gan?: unknown } | null)?.gan;
  if (
    typeof gan !== "string" ||
    gan.trim().length === 0 ||
    gan.length > 128
  ) {
    return jsonResponse({ error: "A valid gift card number is required." }, 400);
  }

  const accessToken = Deno.env.get("SQUARE_ACCESS_TOKEN");
  if (!accessToken) {
    console.error("SQUARE_ACCESS_TOKEN is not configured.");
    return jsonResponse({ error: "Square lookup is not configured." }, 500);
  }

  let squareResponse: Response;
  try {
    squareResponse = await fetch(
      "https://connect.squareupsandbox.com/v2/gift-cards/from-gan",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ gan: gan.trim() }),
      },
    );
  } catch (error) {
    console.error("Square request failed:", error);
    return jsonResponse({ error: "Could not connect to Square Sandbox." }, 502);
  }

  let squareBody: unknown;
  try {
    squareBody = await squareResponse.json();
  } catch {
    console.error("Square returned a non-JSON response.");
    return jsonResponse({ error: "Square returned an invalid response." }, 502);
  }

  if (!squareResponse.ok) {
    console.error(`Square lookup returned HTTP ${squareResponse.status}.`);
    const status = squareResponse.status === 404 ? 404 : 502;
    return jsonResponse(
      {
        error: squareResponse.status === 404
          ? "Gift card was not found in Square Sandbox."
          : `Square lookup failed (${squareResponse.status}).`,
      },
      status,
    );
  }

  const giftCard = (squareBody as {
    gift_card?: {
      id?: unknown;
      state?: unknown;
      balance_money?: { amount?: unknown; currency?: unknown };
    };
  } | null)?.gift_card;
  const amount = giftCard?.balance_money?.amount;
  const currency = giftCard?.balance_money?.currency;

  if (
    typeof giftCard?.id !== "string" ||
    typeof giftCard.state !== "string" ||
    typeof amount !== "number" ||
    !Number.isInteger(amount) ||
    typeof currency !== "string"
  ) {
    console.error("Square response did not contain complete gift card details.");
    return jsonResponse({ error: "Square returned incomplete gift card details." }, 502);
  }

  return jsonResponse({
    giftCard: {
      id: giftCard.id,
      state: giftCard.state,
      balance: { amount, currency },
    },
  });
});
