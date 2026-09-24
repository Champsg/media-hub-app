#!/usr/bin/env python3
"""Generate VidKwaii launcher icon and Play Store icon assets.

Reads the canonical source artwork and writes:
  - adaptive-icon foreground
  - legacy launcher mipmaps
  - Play Store 512x512 icon
  - a launcher preview

Run with the bundled Python (Pillow is required).
"""

import os

from PIL import Image, ImageDraw

MOBILE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLING = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(TOOLING, "icon_source.png")
RES = os.path.join(MOBILE, "android", "app", "src", "main", "res")
PLAY_STORE = os.path.join(MOBILE, "play_store")


def full_bleed(art: Image.Image, size: int) -> Image.Image:
    """Return the artwork resized to fill the whole canvas."""
    return art.resize((size, size), Image.LANCZOS)


def main() -> None:
    if not os.path.exists(SRC):
        raise SystemExit(f"Missing source artwork: {SRC}")
    art = Image.open(SRC).convert("RGBA")

    # Adaptive-icon foreground: artwork fills the whole canvas edge-to-edge.
    fg = full_bleed(art, 1024)
    os.makedirs(os.path.join(RES, "drawable-nodpi"), exist_ok=True)
    fg.save(os.path.join(RES, "drawable-nodpi", "icon_foreground.png"))

    # Legacy launcher mipmaps.
    for density, size in (
        ("mdpi", 48),
        ("hdpi", 72),
        ("xhdpi", 96),
        ("xxhdpi", 144),
        ("xxxhdpi", 192),
    ):
        icon = full_bleed(art, size)
        folder = os.path.join(RES, f"mipmap-{density}")
        os.makedirs(folder, exist_ok=True)
        icon.save(os.path.join(folder, "ic_launcher.png"))
        icon.save(os.path.join(folder, "ic_launcher_round.png"))

    # Play Store 512x512 icon (opaque).
    os.makedirs(PLAY_STORE, exist_ok=True)
    play = full_bleed(art, 512)
    play.convert("RGB").save(os.path.join(PLAY_STORE, "icon_512.png"))

    # Preview so the result can be reviewed before installing.
    launcher = full_bleed(art, 512)
    mask = Image.new("L", (512, 512), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, 511, 511], fill=255)
    launcher.putalpha(mask)
    launcher.save(os.path.join(TOOLING, "preview_icon.png"))

    print("Generated launcher icon and Play Store icon assets.")


if __name__ == "__main__":
    main()
