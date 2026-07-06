#!/usr/bin/env bash
# Streams os_log / NSLog output from the app and the SilenciaBlocker extension on
# the booted simulator. Ctrl-C to stop (or run in the background and read later).
#
#   scripts/logs.sh                 # stream Silencia app + extension logs
#   scripts/logs.sh "emitted"       # only lines matching a substring
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

udid="$(xcrun simctl list devices | grep -F "$SIM_NAME (" | grep -F "(Booted)" | grep -oE '[0-9A-F-]{36}' | head -1 || true)"
[ -n "$udid" ] || die "'$SIM_NAME' is not booted — run scripts/run.sh first"

filter="${1:-}"
info "Streaming Silencia logs from '$SIM_NAME' (Ctrl-C to stop)"
# Match either target by process name; the extension logs under 'SilenciaBlocker'.
pred='processImagePath CONTAINS "Silencia" OR senderImagePath CONTAINS "Silencia"'
if [ -n "$filter" ]; then
  xcrun simctl spawn "$udid" log stream --level debug --predicate "$pred" | grep --line-buffered -i "$filter"
else
  xcrun simctl spawn "$udid" log stream --level debug --predicate "$pred"
fi
