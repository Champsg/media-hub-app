# VidKwaii — Google Play listing package

## App identity

- **App name:** VidKwaii
- **Package:** `com.vidkwaii.app`
- **Version:** 1.0.2 (versionCode 3)
- **Category:** Tools → Downloaders (or Entertainment → Video players & editors)
- **Price:** Free, supported by ads

## Short description (≤ 80 characters)

> Save Instagram videos & reels you have the right to download. Free.

## Full description

> VidKwaii makes saving Instagram videos and reels simple.
>
> • Paste or copy an Instagram link and the app detects it automatically
> • Choose your quality — or let the server combine the best video + audio
> • Download audio-only versions as M4A
> • Saved files land directly in your gallery and music library
> • Offline player with speed controls and keep-screen-on playback
>
> The app is supported by occasional interstitial ads so it can stay free.
>
> Please only download media that you created or have permission to save.
> Respect the rights of content owners and the terms of the platform you are
> saving from.
>
> VidKwaii is an independent tool. It is not affiliated with, endorsed by,
> or sponsored by Instagram or Meta. Instagram is a trademark of Meta
> Platforms, Inc.

## Content rating

Recommended: **Teen (T)**. The app can open Instagram pages in its built-in
browser, so users may encounter user-generated content. Complete the rating
questionnaire honestly and select Teen or higher.

## Data safety (Google Play form answers)

| Question | Answer |
| --- | --- |
| Does the app collect or share user data? | Yes |
| Data types | User-provided Instagram URLs; device/advertising ID and app activity used by the ad SDK (Unity LevelPlay / ironSource) |
| Is data encrypted in transit? | No — the backend is currently reached over HTTP. Deploy HTTPS and then answer "Yes." |
| Data deletion | Downloaded files are deleted by the user; backend temp files auto-delete within 30 minutes |
| Data shared with third parties | Ad partners (through Unity LevelPlay) and the backend hosting provider; no sale of data |
| Account required | No |
| Ads | Interstitial ads shown occasionally before a download (Unity LevelPlay mediation) |

## Permissions declared

- `INTERNET` — fetch media and serve ads
- `WAKE_LOCK` — keep the screen on during playback
- `WRITE_EXTERNAL_STORAGE` (maxSdk 28 only) — legacy gallery save on Android 8/9
- `ACCESS_NETWORK_STATE` — ad SDK network checks
- `ACCESS_ADSERVICES_ATTRIBUTION` — required by Google Play ad-services APIs
- Advertising ID permission — used by the LevelPlay ad SDK

## Release checklist

1. **Deploy HTTPS** in front of the backend and change
   `AppConfig.defaultApiBaseUrl` to the HTTPS URL, then remove
   `android:usesCleartextTraffic="true"` from the manifest.
2. Host `PRIVACY_POLICY.md` at a public URL and enter it in Play Console.
3. Fill in the Data safety form using the table above.
4. Complete the content rating questionnaire honestly (Teen or higher).
5. Upload `play_store/icon_512.png` (512×512), a 1024×500 feature graphic,
   and phone (7″) + tablet (10″) screenshots.
6. Build and upload the **AAB** (not APK) and enable Play App Signing.
7. Run a closed/internal test before production.
8. Keep the Instagram/Meta non-affiliation and "only save content you have
   rights to" language in the listing and in-app.
