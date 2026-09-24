# VidKwaii branding assets

The launcher icon is generated from the source artwork
(`tooling/icon_source.png`):

- `android/app/src/main/res/drawable-nodpi/icon_foreground.png` — adaptive
  icon foreground.
- `android/app/src/main/res/drawable/ic_launcher_background.xml` — launcher
  background color.
- Legacy launcher PNGs in `mipmap-*`.
- `play_store/icon_512.png` — 512×512 Play Store icon.

The launch/splash screen is intentionally a lightweight native vector
(`android/app/src/main/res/drawable/splash_mark.xml`) so the app starts fast.

To swap in new artwork later, replace `tooling/icon_source.png` and run:

```powershell
python tooling/generate_icon_splash.py
```

The script rewrites every icon size and leaves resource references unchanged.
