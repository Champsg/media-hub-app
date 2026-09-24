/**
 * VidKwaii backend-config endpoint (Cloudflare Worker, free plan).
 *
 * This serves the same tiny JSON contract the app reads from its config
 * sources: `{ "api_base_url": "…" }`. To move the backend, change BACKEND_URL
 * below and run:
 *
 *     npx wrangler deploy
 *
 * Installed apps pick the new address up on their next check — no Play Store
 * release, no review, no user action.
 */
const BACKEND_URL = 'http://65.0.74.190';

export default {
  async fetch() {
    const body = JSON.stringify({
      api_base_url: BACKEND_URL,
      updated: new Date().toISOString(),
      source: 'cloudflare-worker',
    });

    return new Response(body, {
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
        'access-control-allow-origin': '*',
      },
    });
  },
};
