# VidKwaii backend-config Worker (free)

Serves the app's backend address so it can be changed without a Play Store
release. Free Cloudflare plan: 100,000 requests/day, which is far more than
this ever needs (one tiny request per app launch).

## Deploy

```bash
cd cloudflare/api-config
npx wrangler login      # one time — opens the browser, free Cloudflare account
npx wrangler deploy
```

`wrangler deploy` prints the URL, for example:

```
https://vidkwaii-config.<your-subdomain>.workers.dev
```

## Connect it to the app

In `lib/core/config/remote_config.dart`, set:

```dart
static const String? workerUrl =
    'https://vidkwaii-config.<your-subdomain>.workers.dev/config.json';
```

The Worker is then checked first, with the GitHub raw file as the automatic
fallback, so the app keeps working even if one of the two is unavailable.

## Changing the backend later

1. Edit `BACKEND_URL` in `src/index.js`.
2. Run `npx wrangler deploy`.

Installed apps switch over on their next check. A value that is missing,
malformed, or unreachable is ignored — the app keeps using the address that
last worked, so a mistake here cannot break the app.

## Alternative with no deploy step

`config.json` in the repository root does the same job: edit `api_base_url` on
github.com and commit. It is wired in as the fallback source and needs no
account or tooling.
