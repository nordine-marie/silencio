#!/usr/bin/env bash
# Regenerates every AppIcon PNG from the vector source of truth
# (docs/design/app-icon.svg). Run after editing the SVG. Idempotent.
#
# The pixel sizes cover every slot in AppIcon.appiconset/Contents.json:
# iPhone (20/29/40/60pt @2x/@3x), iPad (20/29/40/76pt @1x/@2x, 83.5pt @2x)
# and the 1024 App Store marketing icon.
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

command -v rsvg-convert >/dev/null 2>&1 \
  || die "rsvg-convert missing — brew install librsvg (or re-run scripts/bootstrap.sh)"

SVG="$ROOT/docs/design/app-icon.svg"
OUT="$ROOT/App/Assets.xcassets/AppIcon.appiconset"
[ -f "$SVG" ] || die "icon source not found: $SVG"

SIZES=(20 29 40 58 60 76 80 87 120 152 167 180 1024)

info "Rendering ${#SIZES[@]} icon sizes from ${SVG#"$ROOT"/}"
for px in "${SIZES[@]}"; do
  rsvg-convert --width "$px" --height "$px" --background-color '#A8443A' \
    "$SVG" -o "$OUT/icon-$px.png"
  ok "icon-$px.png"
done

ok "AppIcon PNGs regenerated in ${OUT#"$ROOT"/}"
