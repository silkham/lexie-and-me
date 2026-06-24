/*
 * Lexie & Me — Cloudflare Worker proxy for the Anthropic API
 * --------------------------------------------------------------
 * This sits between the app and Anthropic. The app sends its request
 * here; this Worker adds the secret API key (stored as a Cloudflare
 * Secret named ANTHROPIC_API_KEY) and forwards it on. The key never
 * touches your public GitHub repo.
 *
 * Setup: paste this into your Worker's editor, Deploy, then add the
 * secret ANTHROPIC_API_KEY under Settings → Variables and Secrets.
 */

export default {
  async fetch(request, env) {
    // Only allow your own app to use this Worker. Add your GitHub Pages origin.
    // Find it after Stage 1: it's the https://NAME.github.io part of your app URL
    // (no path, no trailing slash). You can list more than one.
    const ALLOWED = [
      "https://silkham.github.io",
    ];
    const origin = request.headers.get("Origin") || "";
    const ok = ALLOWED.includes(origin);
    const cors = {
      "Access-Control-Allow-Origin": ok ? origin : ALLOWED[0],
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
      "Vary": "Origin",
    };
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: cors });
    }
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405, headers: cors });
    }
    if (!ok) {
      return new Response(JSON.stringify({ error: "Origin not allowed" }),
        { status: 403, headers: { ...cors, "Content-Type": "application/json" } });
    }

    try {
      const body = await request.text(); // pass the app's JSON straight through

      const resp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": env.ANTHROPIC_API_KEY,      // the secret, injected here
          "anthropic-version": "2023-06-01",
        },
        body,
      });

      const data = await resp.text();
      return new Response(data, {
        status: resp.status,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    } catch (err) {
      return new Response(
        JSON.stringify({ error: String(err) }),
        { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }
  },
};
