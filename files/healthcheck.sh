#!/bin/bash
set -euo pipefail

TARGET="${SERVER:-smart}"
WAIT_SECONDS="${HEALTHCHECK_RECONNECT_WAIT:-15}"

is_connected() {
  [[ "$(expressvpnctl get connectionstate 2>/dev/null || true)" == "Connected" ]] && [[ -d /sys/class/net/tun0 ]]
}

try_reconnect() {
  expressvpnctl connect "$TARGET" >/dev/null 2>&1 || return 1
  local i
  for i in $(seq 1 "$WAIT_SECONDS"); do
    is_connected && return 0
    sleep 1
  done
  return 1
}

main() {
  expressvpnctl status >/dev/null 2>&1 || exit 1

  if is_connected; then
    exit 0
  fi

  try_reconnect || exit 1
}

main
