# VidKwaii - Server Switch panel (Cloudflare Worker, free)

A password-protected web page for changing the backend address your app reads at
startup. The GitHub token lives here as a Worker secret, so it is never stored
in a browser or typed into a phone.

It works by rewriting `config.json` in `Champsg/media-hub-app` - the same file
the app already fetches - so **the app needs no update to follow a switch**.

## One-time setup

Run these from this folder (`mobile/cloudflare/server-switch`):

```
npx wrangler login                     # opens the browser once, free Cloudflare account
npx wrangler secret put ADMIN_PASSWORD # the password you will type to open the panel
npx wrangler secret put GITHUB_TOKEN   # fine-grained PAT, Contents: Read and write
npx wrangler deploy
```

`wrangler deploy` prints the panel URL, for example:

```
https://vidkwaii-server-switch.<your-subdomain>.workers.dev
```

Open that URL, sign in with your `ADMIN_PASSWORD`, and you are done. Bookmark it
- it works from your phone too.

## Creating the GitHub token

1. github.com -> avatar -> Settings -> Developer settings.
2. Personal access tokens -> Fine-grained tokens -> Generate new token.
3. Name it `VidKwaii server switch`; pick an expiry (calendar a reminder - the
   panel stops switching when it expires; the app is unaffected).
4. Repository access: Only select repositories -> `Champsg/media-hub-app`.
5. Permissions -> Repository permissions -> **Contents: Read and write**.
6. Generate and copy the `github_pat_...` value - it is shown once. Paste it into
   the `wrangler secret put GITHUB_TOKEN` prompt.

## Using the panel

- **Test** checks a server through the Worker, so `http://` backends work even
  though the panel itself is on `https`.
- **Switch** writes the address. Apps pick it up within about 5 minutes.
- If a server does not answer, the panel warns you and asks before forcing it -
  and the app independently verifies a new address before switching, so a dead
  or mistyped server cannot lock users out.

## Notes

- Free plan: 100,000 requests/day, far more than this needs. You are the only
  user, since every page and API call requires the password.
- For a second lock, put Cloudflare Access in front of the Worker (Zero Trust ->
  Access -> Applications) so it also demands an email one-time code.
- To point this at a different repo or branch, edit `REPO` and `BRANCH` at the
  top of `src/index.js` and deploy again.
- Secrets live only in Cloudflare. `wrangler secret list` shows their names, never
  their values. To rotate the GitHub token, run the `secret put` command again.