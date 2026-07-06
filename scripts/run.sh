#!/usr/bin/env bash
# Builds, installs, and launches the app on a booted simulator, then captures a
# screenshot so an agent can visually confirm the running app. Fully non-interactive.
#
#   scripts/run.sh                       # build + launch + screenshot
#   SIM_NAME="iPhone 17 Pro" scripts/run.sh
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

[ -d "$XCODEPROJ" ] || die "no .xcodeproj — run scripts/gen.sh first"

udid="$(ensure_booted_sim)"
info "Simulator '$SIM_NAME' ready ($udid)"

# Build for this specific simulator so the product is installable.
info "Building for simulator"
set -o pipefail
xcodebuild build \
  -project "$XCODEPROJ" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "id=$udid" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO | beautify

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/$PROJECT_NAME.app"
[ -d "$APP_PATH" ] || die "app not found at $APP_PATH"

info "Installing and launching $APP_BUNDLE_ID"
xcrun simctl install "$udid" "$APP_PATH"
xcrun simctl launch "$udid" "$APP_BUNDLE_ID" >/dev/null
sleep 2  # let SwiftUI render the first frame

shot_dir="$ROOT/.context/screenshots"
mkdir -p "$shot_dir"
shot="$shot_dir/launch-$(date +%Y%m%d-%H%M%S).png"
xcrun simctl io "$udid" screenshot "$shot" >/dev/null 2>&1
ok "Launched. Screenshot: $shot"
echo "$shot"
