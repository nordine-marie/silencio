#!/usr/bin/env bash
# Regenerates Silencia.xcodeproj from project.yml. The .xcodeproj is a build
# artifact (gitignored) — this is the only supported way to change project config.
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

command -v xcodegen >/dev/null 2>&1 || die "xcodegen missing — run scripts/bootstrap.sh"

info "Generating $PROJECT_NAME.xcodeproj from project.yml"
( cd "$ROOT" && xcodegen generate )
ok "Generated $XCODEPROJ"
