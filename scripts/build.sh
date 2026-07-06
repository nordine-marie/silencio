#!/usr/bin/env bash
# Builds the app for the iOS Simulator into a deterministic DerivedData path and
# prints the resulting .app bundle path (used by run.sh).
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

[ -d "$XCODEPROJ" ] || die "no .xcodeproj — run scripts/gen.sh first"

info "Building $SCHEME for iOS Simulator"
set -o pipefail
xcodebuild build \
  -project "$XCODEPROJ" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO | beautify

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/$PROJECT_NAME.app"
[ -d "$APP_PATH" ] || die "build succeeded but app not found at $APP_PATH"
ok "Built: $APP_PATH"
echo "$APP_PATH"
