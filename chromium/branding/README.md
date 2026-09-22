# Launcher branding

Source: `src/assets/images/icon.png`; its SHA-256 is in `source.sha256`.
Generated with ImageMagick 6, using the existing source without redesign:

- Legacy `app_icon.png`: 48 dp at mdpi through xxxhdpi.
- Adaptive `layered_app_icon.png`: original image fit inside 66 dp on a
  transparent 108 dp canvas. Red background is a separate 108 dp resource.
- Both normal and round launcher XML use this same adaptive foreground.
  The upstream Chromium monochrome glyph is omitted so themed launchers
  cannot display a Chromium logo for ADB Browser.

`branding.py` checks the upstream XML SHA-256 before changing labels and
launcher XML, and checks that every raster destination exists. It is
idempotent for a resumed build. APK verification compares the highest-density
packaged foreground pixels against the committed image.

Recreate PNGs with `convert`: resize the source to 48*density for legacy,
resize to 66*density then center/extend to 108*density for adaptive foreground,
and generate `xc:#e93430` at 108*density for the background.
