/**
 * VidKwaii - API Gateway (Cloudflare Worker, free plan)
 *
 * One stable address, several backends:
 *
 *   Android app  ->  https://api.yourapp.com  ->  this Worker
 *                                                    |-- Backend #1 (Lightsail)
 *                                                    `-- Backend #2 (backup)
 *
 * The app never depends on a server IP. If the primary stops answering
 * /health, requests go to the next backend automatically.
 *
 * Deploy: see README.md. Set the backends in ORIGINS below.
 */

const ORIGINS = [
  // Workers cannot fetch a bare IP address (Cloudflare replies 1003), so the
  // origin is addressed by a hostname that resolves to the Lightsail IP.
  // Swap this for origin.yourdomain.com once a domain is on the account.
  { name: 'lightsail-primary', url: 'http://13.127.33.222.nip.io' },
  // { name: 'backup-vps', url: 'http://YOUR.BACKUP.IP' },
];

const HEALTH_PATH = '/health';
const HEALTH_TTL_MS = 15000;      // how long a health verdict is reused
const HEALTH_TIMEOUT_MS = 4000;
const REQUEST_TIMEOUT_MS = 120000; // merge jobs on the backend can take minutes
// Merged media is streamed by the backend. Set true to 302-redirect those
// downloads straight to the origin instead of passing video through
// Cloudflare (free-plan terms discourage large non-HTML proxying).
const REDIRECT_MEDIA_DOWNLOADS = false;

const healthCache = new Map();

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (url.pathname === '/__gateway/status') {
      return json(await status());
    }

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const isMediaDownload = url.pathname.startsWith('/api/v1/files/');
    const order = await orderedOrigins();
    if (!order.length) return json({ error: 'no backends configured' }, 503);

    if (REDIRECT_MEDIA_DOWNLOADS && isMediaDownload) {
      const target = order[0];
      return Response.redirect(target.url + url.pathname + url.search, 302);
    }

    let lastError = 'no attempt made';
    for (const origin of order) {
      try {
        const response = await proxy(request, origin, url);
        if (response.status < 500) {
          markHealthy(origin, true);
          return withCors(response);
        }
        if (response.status >= 500) {
          markHealthy(origin, false);
          lastError = origin.name + ' answered HTTP ' + response.status;
          continue;
        }
        return withCors(response);
      } catch (err) {
        markHealthy(origin, false);
        lastError = origin.name + ' unreachable: ' + String((err && err.message) || err);
      }
    }

    return json({ error: 'all backends failed', detail: lastError, tried: order.map((o) => o.name) }, 503);
  },
};

/* ---------------------------------------------------------------- routing */

async function orderedOrigins() {
  const now = Date.now();
  const ranked = [];

  for (const origin of ORIGINS) {
    const cached = healthCache.get(origin.url);
    if (!cached || now - cached.at > HEALTH_TTL_MS) {
      const health = await probe(origin);
      healthCache.set(origin.url, { healthy: health.ok, at: now, latencyMs: health.latencyMs });
      ranked.push({ ...origin, healthy: health.ok });
    } else {
      ranked.push({ ...origin, healthy: cached.healthy });
    }
  }

  const healthy = ranked.filter((o) => o.healthy);
  const unhealthy = ranked.filter((o) => !o.healthy);
  return [...healthy, ...unhealthy]; // healthy first, but try others rather than giving up
}

async function probe(origin) {
  const started = Date.now();
  try {
    const res = await fetch(origin.url + HEALTH_PATH, {
      signal: AbortSignal.timeout(HEALTH_TIMEOUT_MS),
      headers: { 'cache-control': 'no-cache' },
    });
    return { ok: res.ok, latencyMs: Date.now() - started };
  } catch (err) {
    return { ok: false, latencyMs: Date.now() - started };
  }
}

function markHealthy(origin, healthy) {
  healthCache.set(origin.url, { healthy, at: Date.now(), latencyMs: null });
}

async function proxy(request, origin, url) {
  const headers = new Headers(request.headers);
  headers.delete('host');
  headers.delete('cf-connecting-ip');
  headers.set('x-forwarded-proto', 'https');
  headers.set('x-forwarded-host', url.host);
  const clientIp = request.headers.get('cf-connecting-ip');
  if (clientIp) headers.set('x-forwarded-for', clientIp);

  const init = {
    method: request.method,
    headers,
    redirect: 'manual',
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  };
  if (request.method !== 'GET' && request.method !== 'HEAD') init.body = request.body;

  return await fetch(origin.url + url.pathname + url.search, init);
}

async function status() {
  const rows = [];
  for (const origin of ORIGINS) {
    const cached = healthCache.get(origin.url);
    const health = await probe(origin);
    rows.push({
      name: origin.name,
      url: origin.url,
      healthy: health.ok,
      latencyMs: health.latencyMs,
      cachedHealthy: cached ? cached.healthy : null,
    });
  }
  return { gateway: 'vidkwaii-api-gateway', origins: rows, checkedAt: new Date().toISOString() };
}

/* ---------------------------------------------------------------- helpers */

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Max-Age': '86400',
  };
}

function withCors(response) {
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(corsHeaders())) headers.set(key, value);
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

function json(data, status) {
  return new Response(JSON.stringify(data, null, 2), {
    status: status || 200,
    headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', ...corsHeaders() },
  });
}