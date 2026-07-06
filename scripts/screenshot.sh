#!/usr/bin/env bash
# Captures a screenshot of the booted simulator so an agent can "see" the app.
#   scripts/screenshot.sh [output.png]
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

udid="$(xcrun simctl list devices | grep -F "$SIM_NAME (" | grep -F "(Booted)" | grep -oE '[0-9A-F-]{36}' | head -1 || true)"
[ -n "$udid" ] || die "'$SIM_NAME' is not booted — run scripts/run.sh first"

out="${1:-$ROOT/.context/screenshots/shot-$(date +%Y%m%d-%H%M%S).png}"
mkdir -p "$(dirname "$out")"
xcrun simctl io "$udid" screenshot "$out"
ok "Saved $out"
echo "$out"
