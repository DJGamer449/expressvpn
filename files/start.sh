#!/bin/bash
set -euo pipefail

log() {
  echo "[start] $*"
}

restore_resolver() {
  local resolv="/etc/resolv.conf"
  if [[ -f "$resolv" ]]; then
    cp "$resolv" "${resolv}.bak"
    umount "$resolv" &>/dev/null || true
    cp "${resolv}.bak" "$resolv"
    rm -f "${resolv}.bak"
  fi
}

restart_service() {
  local service_name=""
  if [[ -f /etc/init.d/expressvpn-service ]]; then
    service_name="expressvpn-service"
  elif [[ -f /etc/init.d/expressvpn ]]; then
    service_name="expressvpn"
  fi

  if [[ -z "$service_name" ]]; then
    log "Unable to locate expressvpn init script"
    exit 1
  fi

  service "$service_name" stop >/dev/null 2>&1 || true
  service "$service_name" start >/dev/null 2>&1
}

activate_account() {
  if [[ -z ${CODE:-} ]]; then
    log "Activation code is required (CODE)."
    exit 1
  fi

  local code_file
  code_file=$(mktemp)
  printf '%s' "${CODE}" >"${code_file}"

  if ! output=$(expressvpnctl --timeout 60 login "${code_file}" 2>&1); then
    rm -f "${code_file}"
    if grep -qi "Already logged into account" <<<"$output"; then
      log "Already logged in; skipping activation."
      return
    fi
    echo "$output"
    exit 1
  fi

  rm -f "${code_file}"
  expressvpnctl background enable >/dev/null 2>&1 || true
}

set_protocol() {
  local value="${PROTOCOL:-lightwayudp}"
  value="${value,,}"
  case "$value" in
    auto|lightwayudp|lightwaytcp|openvpnudp|openvpntcp|wireguard)
      expressvpnctl set protocol "$value" >/dev/null 2>&1 || true
      ;;
    *)
      log "Unsupported PROTOCOL value: ${value}"
      exit 1
      ;;
  esac
}

connect_vpn() {
  local target="${SERVER:-smart}"
  expressvpnctl disconnect >/dev/null 2>&1 || true
  expressvpnctl connect "$target"
  expressvpnctl set autoconnect true >/dev/null 2>&1 || true
}

main() {
  command -v expressvpnctl >/dev/null 2>&1 || { log "expressvpnctl not found"; exit 1; }

  restore_resolver
  restart_service
  activate_account
  set_protocol
  connect_vpn

  if [[ $# -gt 0 ]]; then
    exec "$@"
  fi

  exec sleep infinity
}

main "$@"
