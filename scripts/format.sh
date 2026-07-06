#!/usr/bin/env bash
# Formats all Swift sources with swiftformat (config: .swiftformat).
#   scripts/format.sh          # rewrite files in place
#   scripts/format.sh --lint   # check only, non-zero exit if changes needed (CI)
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

command -v swiftformat >/dev/null 2>&1 || die "swiftformat missing — run scripts/bootstrap.sh"

if [ "${1:-}" = "--lint" ]; then
  info "Checking formatting"
  swiftformat --lint "$ROOT/App" "$ROOT/Blocker" "$PACKAGE_DIR/Sources" "$PACKAGE_DIR/Tests"
  ok "Formatting OK"
else
  info "Formatting Swift sources"
  swiftformat "$ROOT/App" "$ROOT/Blocker" "$PACKAGE_DIR/Sources" "$PACKAGE_DIR/Tests"
  ok "Formatted"
fi
