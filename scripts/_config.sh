#!/usr/bin/env bash
# Shared configuration + helpers sourced by every harness script.
# Not meant to be run directly.
set -euo pipefail

# Repo root, regardless of where a script is invoked from.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Project constants (keep in sync with project.yml) ---
PROJECT_NAME="Silencia"
XCODEPROJ="$ROOT/Silencia.xcodeproj"
SCHEME="Silencia"
APP_BUNDLE_ID="com.silencia.app"
PACKAGE_DIR="$ROOT/SilenciaKit"

# Deterministic build output so scripts can find products without guessing.
DERIVED_DATA="$ROOT/.build/DerivedData"

# Default simulator. Override with:  SIM_NAME="iPhone 17 Pro" scripts/run.sh
SIM_NAME="${SIM_NAME:-iPhone 17}"

# --- Pretty output ---
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

info()  { printf "%s==>%s %s\n" "$BLUE$BOLD" "$RESET" "$*"; }
ok()    { printf "%s✓%s %s\n" "$GREEN" "$RESET" "$*"; }
warn()  { printf "%s!%s %s\n" "$YELLOW" "$RESET" "$*"; }
fail()  { printf "%s✗%s %s\n" "$RED" "$RESET" "$*" >&2; }
die()   { fail "$*"; exit 1; }

# Pipe xcodebuild through xcbeautify when available; otherwise pass through raw.
beautify() {
  if command -v xcbeautify >/dev/null 2>&1; then
    xcbeautify "$@"
  else
    cat
  fi
}

# Resolve a booted simulator UDID for SIM_NAME, booting one if needed.
# Echoes the UDID on stdout.
ensure_booted_sim() {
  local udid
  udid="$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | head -1 \
    | grep -oE '[0-9A-F-]{36}' || true)"
  [ -n "$udid" ] || die "no available simulator named '$SIM_NAME' (see: xcrun simctl list devices)"

  local state
  state="$(xcrun simctl list devices | grep "$udid" | grep -oE '\((Booted|Shutdown|Booting)\)' | tr -d '()' || true)"
  if [ "$state" != "Booted" ]; then
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    # Best-effort: surface the Simulator UI so screenshots/interaction work.
    open -a Simulator >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || true
  fi
  echo "$udid"
}
