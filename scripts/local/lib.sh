#!/usr/bin/env bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOGS="$ROOT/.dev-logs"
PIDS="$LOGS/pids"

declare -A PORT=(
  [auth]=4001 [patient]=4002 [doctor]=4003 [appointment]=4004
  [consultation]=4005 [messaging]=4006 [followup]=4007
  [notification]=4008 [ai]=4009 [emergency]=4010 [pharmacy]=4011
  [payment]=4012 [diagnostics]=4013 [quality]=4014 [families]=4015
  [education]=4016 [network]=4017 [insurance]=4018 [research]=4019
  [surveillance]=4020 [gateway]=4021 [sync]=4022 [devices]=4023
  [prevention]=4024 [facilities]=4025
  [web-app]=3000 [doctor-app]=3100 [admin-app]=3200 [analytics-app]=3300
)

CORE_SERVICES=(
  auth patient doctor appointment consultation messaging followup notification
  ai emergency pharmacy payment diagnostics quality families education network
  insurance research surveillance sync devices prevention facilities gateway
)

app_pkg() {
  case "$1" in
    doctor-app) echo doctor-dashboard ;;
    admin-app) echo admin-console ;;
    analytics-app) echo analytics-portal ;;
    web-app) echo a-health-web ;;
    *) return 1 ;;
  esac
}

pid_alive() {
  local pid="${1:-}"
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

pid_owned_by_ahp() {
  local pid="$1"
  local cwd cmd
  cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
  cmd="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
  [[ "$cwd" == "$ROOT"* || "$cmd" == *"$ROOT"* || "$cmd" == *"@a-health/"* || "$cmd" == *"next dev -p"* ]]
}

port_active() {
  local port="$1" hex
  hex="$(printf '%04X' "$port")"
  awk -v h=":$hex" '$2 ~ h && $4 == "0A" { found = 1 } END { exit found ? 0 : 1 }' \
    /proc/net/tcp /proc/net/tcp6 2>/dev/null
}

port_pid() {
  local port="$1" hex inode pid
  hex="$(printf '%04X' "$port")"
  while read -r inode; do
    [ -n "$inode" ] || continue
    while read -r pid; do
      [ -n "$pid" ] && { echo "$pid"; return 0; }
    done < <(
      find /proc/[0-9]*/fd -lname "socket:\\[$inode\\]" 2>/dev/null |
        sed -n 's#/proc/\([0-9]*\)/fd/.*#\1#p'
    )
  done < <(
    awk -v h=":$hex" '$2 ~ h && $4 == "0A" { print $10 }' \
      /proc/net/tcp /proc/net/tcp6 2>/dev/null
  )
  return 1
}

remembered_pid() {
  local name="$1"
  [ -f "$PIDS/$name.pid" ] && sed -n '1p' "$PIDS/$name.pid"
}

record_listener() {
  local name="$1" port="$2" pid="${3:-}"
  mkdir -p "$PIDS"
  if [ -n "$pid" ]; then
    echo "$pid" > "$PIDS/$name.pid"
  else
    echo "port:$port" > "$PIDS/$name.pid"
  fi
}

tmux_session_name() {
  local name="$1"
  echo "ahp-${name//[^A-Za-z0-9_-]/-}"
}

tmux_alive() {
  local session="$1"
  command -v tmux >/dev/null 2>&1 && tmux has-session -t "$session" 2>/dev/null
}

record_tmux() {
  local name="$1" session="$2"
  mkdir -p "$PIDS"
  echo "tmux:$session" > "$PIDS/$name.pid"
}

name_port() {
  local name="$1"
  echo "${PORT[$name]:-}"
}
