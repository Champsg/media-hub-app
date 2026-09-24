# VidKwaii — Flutter Android client

Store-facing Flutter app that saves public Instagram videos and reels the
user has permission to download, with an in-app browser, offline library and
player.

## Architecture

```
lib/
├── core/          Config, theme, constants, utils, shared widgets
├── data/          Models, Dio API client, DownloaderService (chunked,
│                  pause/resume), HLS stitcher, media-scanner bridge
├── logic/         Riverpod controllers (extract, download, library,
│                  clipboard, browser) + providers
└── presentation/  App shell, screens and feature widgets
```

## Setup

```bash
cd mobile
flutter pub get
flutter run
```

The app's Android entry point is
`android/app/src/main/kotlin/com/vidkwaii/app/MainActivity.kt`, which exposes
the `media_hub/media_scanner` platform channel for gallery export.

## Backend URL

The release default is in
`lib/core/config/app_config.dart` (`AppConfig.defaultApiBaseUrl`). The
current backend is reachable over plain HTTP, so the manifest enables
cleartext traffic. Before a production Play release, serve the backend over
HTTPS, update the URL, and remove `android:usesCleartextTraffic="true"`.

## Key features

- **Instagram link detection** — clipboard polling surfaces Instagram links on
  the home screen; other links are rejected with a clear message.
- **Format picker** — choose quality or let the server combine the best
  video + audio; audio-only M4A is supported.
- **Download manager** — parallel range-request chunks with pause/resume,
  per-task progress, speed and ETA.
- **HLS stitcher** — `.m3u8` playlists are downloaded segment-by-segment and
  concatenated locally; encrypted playlists are rejected with a clear message.
- **Smart browser** — starts at Instagram, injects a sniffer for media URLs,
  and shows a one-tap download button for Instagram media.
- **Player** — `video_player` + Chewie with speed controls and keep-screen-on.
- **Ads** — Unity LevelPlay interstitial ads before downloads; see
  `lib/data/services/ad_service.dart` and the Play privacy policy.

## Release build

```bash
flutter build appbundle --release
```

The signed AAB is written to
`build/app/outputs/bundle/release/app-release.aab`. Follow
`play_store/listing.md` for the Play Console steps.

## Legal

Only save media you created or have permission to download. VidKwaii is not
affiliated with Instagram or Meta.
