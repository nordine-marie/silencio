#!/usr/bin/env bash
# Runs the test suite.
#   scripts/test.sh            # headless `swift test` on SilenciaKit (the primary loop)
#   scripts/test.sh --all      # also builds the app for the iOS Simulator (toolchain check)
#
# All meaningful logic lives in SilenciaKit and is tested headless: no simulator,
# sub-second, deterministic — the identical Swift 6 code the iOS targets link.
# Real call-blocking behavior can only be verified on a physical device
# (implementation-plan.md §2.5); a simulator cannot place phone calls.
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

info "SilenciaKit — headless logic tests (swift test)"
( cd "$PACKAGE_DIR" && swift test )
ok "SilenciaKit tests passed"

if [ "${1:-}" = "--all" ]; then
  [ -d "$XCODEPROJ" ] || die "no .xcodeproj — run scripts/gen.sh first"
  info "Building the app for the iOS Simulator (compile/link check of the iOS targets)"
  "$ROOT/scripts/build.sh" >/dev/null
  ok "Simulator build succeeded"
fi
