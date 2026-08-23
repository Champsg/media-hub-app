# Media Hub — Flutter Client

Universal media grabber with an HLS segment stitcher, a smart in-app browser,
an offline media library and a WhatsApp status vault backed by the Storage
Access Framework.

## Architecture

```
lib/
├── core/          Config, theme, constants, utils, shared widgets
├── data/          Models, Dio API client, DownloaderService (chunked,
│                  pause/resume), HLS stitcher, MediaScanner bridge,
│                  SAF vault service, repository
├── logic/         Riverpod controllers (extract, download, library,
│                  clipboard, browser, vault, settings) + providers
└── presentation/  App shell, screens and feature widgets
```

## Setup

```bash
cd mobile
flutter pub get
flutter create . --project-name media_hub --org com.mediahub
flutter run
```

`flutter create .` only generates missing platform scaffolding (gradle
wrapper, iOS shell, etc.) and does not overwrite the files provided here.
The app's Android entry point is
`android/app/src/main/kotlin/com/mediahub/downloader/MainActivity.kt`, which
registers the `media_hub/media_scanner` and `media_hub/saf` platform channels.

> Note: `flutter create` also generates an unused default
> `MainActivity.kt` under `com/mediahub/media_hub/`. You can delete it; the
> manifest registers `.MainActivity` under `com.mediahub.downloader`.

## Connecting to the backend

- **Android emulator:** the default `http://10.0.2.2:8000` reaches the host.
- **Physical device:** open Settings → Server URL and enter your computer's
  LAN IP, e.g. `http://192.168.1.10:8000`.

Cleartext HTTP is enabled for development
(`android:usesCleartextTraffic="true"`); remove it if you point at an HTTPS
server in production.

## Troubleshooting

**`Gradle build failed due to Java/Gradle incompatibility`** — this project is
pinned to the Gradle 9.3.1 / AGP 9.1.0 / Kotlin 2.4.0 stack that ships with
Flutter 3.47.x, which supports JDK 21 and 25. If you see this error, your
`gradle-wrapper.properties` was reverted to an older Gradle (e.g. 8.4) —
restore it to `gradle-9.3.1-all.zip` and re-run.

The first build downloads the Gradle distribution, Android dependencies and
the NDK (several GB) from `services.gradle.org` / `dl.google.com`, so it
needs a working internet connection and can take a while. Connection timeouts
to `services.gradle.org` are network issues — retry, check your proxy/VPN, or
run the build from a normal terminal rather than a sandboxed one.

## Key features

- **Universal grabber** — clipboard polling surfaces media links on the home
  screen; the FastAPI backend resolves them into normalized formats.
- **HLS stitcher** — `.m3u8` playlists are downloaded segment-by-segment
  (highest-bandwidth variant is selected from master playlists) and
  concatenated locally. AES-128 encrypted streams are rejected with a clear
  message; the output may need remuxing for non-TS variants.
- **Smart browser** — `WebSniffer` injects a hook script that captures media
  URLs from `fetch`, XHR, `<video>/<audio>` and resource timing, then shows a
  floating one-tap download button.
- **Download manager** — parallel range-request chunks with pause/resume,
  per-task progress, speed and ETA, broadcast over a stream.
- **WhatsApp vault** — SAF folder picker (native channel) walks the tree,
  filters status media, previews and saves it into the app vault.
- **Player** — `video_player` + Chewie with speed controls, fullscreen and a
  keep-screen-on toggle (wakelock).
