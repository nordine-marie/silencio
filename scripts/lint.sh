#!/usr/bin/env bash
# Lints all Swift sources with swiftlint (config: .swiftlint.yml).
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

command -v swiftlint >/dev/null 2>&1 || die "swiftlint missing — run scripts/bootstrap.sh"

info "Linting Swift sources"
( cd "$ROOT" && swiftlint lint --quiet )
ok "Lint clean"
