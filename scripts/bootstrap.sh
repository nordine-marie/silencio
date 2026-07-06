#!/usr/bin/env bash
# One-time setup: installs the optional Homebrew tools the harness uses, then
# generates the Xcode project. Idempotent — safe to re-run.
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

command -v brew >/dev/null 2>&1 || die "Homebrew required: https://brew.sh"

TOOLS=(xcodegen xcbeautify swiftlint swiftformat)
to_install=()
for t in "${TOOLS[@]}"; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t already installed"; else to_install+=("$t"); fi
done

if [ "${#to_install[@]}" -gt 0 ]; then
  info "Installing: ${to_install[*]}"
  brew install "${to_install[@]}"
fi

# librsvg ships the rsvg-convert binary scripts/icons.sh uses (formula name ≠ command name).
if command -v rsvg-convert >/dev/null 2>&1; then
  ok "rsvg-convert already installed"
else
  info "Installing: librsvg"
  brew install librsvg
fi

info "Generating Xcode project"
"$ROOT/scripts/gen.sh"

ok "Bootstrap complete. Try: scripts/doctor.sh"
