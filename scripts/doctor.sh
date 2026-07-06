#!/usr/bin/env bash
# Environment doctor: verifies every tool the harness needs and reports what's
# missing. Read-only and safe to run any time. Exit code is non-zero if a REQUIRED
# tool is missing (optional tools only warn).
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

missing_required=0

check_required() {
  local name="$1"; shift
  if command -v "$name" >/dev/null 2>&1; then
    ok "$name — $("$@" 2>&1 | head -1)"
  else
    fail "$name — MISSING (required)"
    missing_required=1
  fi
}

check_optional() {
  local name="$1"; local hint="$2"
  if command -v "$name" >/dev/null 2>&1; then
    ok "$name — $(command -v "$name")"
  else
    warn "$name — not installed ($hint)"
  fi
}

info "Silencia environment doctor"
echo

info "Required toolchain"
check_required xcodebuild xcodebuild -version
check_required swift swift --version
check_required xcrun xcrun --version
if xcode-select -p >/dev/null 2>&1; then
  ok "xcode-select — $(xcode-select -p)"
else
  fail "xcode-select — no active developer dir"; missing_required=1
fi
echo

info "Optional tooling (run scripts/bootstrap.sh to install)"
check_optional xcodegen  "brew install xcodegen — needed to generate the .xcodeproj"
check_optional xcbeautify "brew install xcbeautify — prettier build output"
check_optional swiftlint  "brew install swiftlint — linting"
check_optional swiftformat "brew install swiftformat — formatting"
check_optional jq          "brew install jq — used by some scripts"
echo

info "iOS simulator runtimes"
if xcrun simctl list runtimes available 2>/dev/null | grep -qi ios; then
  xcrun simctl list runtimes available | grep -i ios | sed 's/^/    /'
else
  fail "no iOS simulator runtimes installed"; missing_required=1
fi
echo

info "Target simulator: $SIM_NAME"
if xcrun simctl list devices available | grep -qF "$SIM_NAME ("; then
  ok "'$SIM_NAME' is available"
else
  warn "'$SIM_NAME' not found — set SIM_NAME to one of:"
  xcrun simctl list devices available | grep -iE 'iphone' | sed 's/^/    /' | head -8
fi
echo

info "Project state"
[ -d "$PACKAGE_DIR" ] && ok "SilenciaKit package present" || warn "SilenciaKit package missing"
if [ -d "$XCODEPROJ" ]; then
  ok "Silencia.xcodeproj generated"
else
  warn "Silencia.xcodeproj not generated yet — run scripts/gen.sh"
fi
echo

if [ "$missing_required" -eq 0 ]; then
  ok "${BOLD}Environment is ready.${RESET}"
  echo "    Next: scripts/test.sh (headless logic) · scripts/gen.sh + scripts/run.sh (app in simulator)"
else
  die "Environment is missing required tools (see above)."
fi
