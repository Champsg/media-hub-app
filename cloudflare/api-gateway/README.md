# VidKwaii - API gateway with failover (Cloudflare Worker, free)

Gives the app one permanent address while you run one, two or three backends
behind it:

```
Android app  ->  https://api.yourapp.com  ->  Worker
                                                 |-- lightsail-primary
                                                 `-- backup-vps
```

If the primary stops answering `/health`, requests go to the next backend. The
app never learns a server IP, so nothing needs rebuilding when you move or add
a backend.

## 1. List your backends

Edit `ORIGINS` at the top of `src/index.js`:

```js
const ORIGINS = [
  { name: 'lightsail-primary', url: 'http://65.0.74.190' },
  { name: 'backup-vps',        url: 'http://YOUR.BACKUP.IP' },
];
```

Order matters: the first healthy entry wins. Leaving the backup commented out is
fine - add it when that server exists.

## 2. Deploy

```
npx wrangler login      # once
npx wrangler deploy
```

You get a free `https://vidkwaii-api-gateway.<subdomain>.workers.dev` address.
Check it any time:

```
https://<your-worker-url>/__gateway/status
```

That reports each backend, whether it is healthy, and its latency.

## 3. Point your domain at it (optional but recommended)

In the Cloudflare dashboard: Workers & Pages -> vidkwaii-api-gateway ->
Settings -> Domains & Routes -> Add -> Custom Domain -> `api.yourapp.com`.

Then in the app's config (`config.json` in the repo root) set:

```json
{ "api_base_url": "https://api.yourapp.com" }
```

Every installed app picks that up within about 5 minutes - no Play release. Apps
verify the new address answers before switching, so a mistake cannot lock users
out.

## Benefits beyond failover

- **HTTPS for free.** Your Lightsail box can keep serving plain HTTP; Cloudflare
  terminates TLS in front of it. That also resolves the mismatch where your Play
  Data safety form says data is encrypted in transit.
- **Hide your origin.** The app only ever sees Cloudflare.

## One thing to know

The backend's merge endpoint streams finished `.mp4` files. Cloudflare's free
plan discourages proxying large non-HTML content, so `REDIRECT_MEDIA_DOWNLOADS`
in `src/index.js` can be set to `true`: API calls go through the Worker, while
media downloads get a 302 straight to the origin. Turn it on if you start
shifting serious video volume; for small traffic the default is fine.