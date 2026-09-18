#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

printf "%-18s %-8s %-10s %s\n" "name" "pid" "state" "detail"

if [ ! -d "$PIDS" ]; then
  echo "No AHP pid directory found."
  exit 0
fi

for file in "$PIDS"/*.pid; do
  [ -e "$file" ] || continue
  name="$(basename "$file" .pid)"
  value="$(sed -n '1p' "$file")"
  port="$(name_port "$name")"

  if [[ "$value" == tmux:* ]]; then
    session="${value#tmux:}"
    if tmux_alive "$session" && [ -n "$port" ] && port_active "$port"; then
      printf "%-18s %-8s %-10s %s\n" "$name" "tmux" "running" "session $session; port $port listening"
    elif tmux_alive "$session"; then
      printf "%-18s %-8s %-10s %s\n" "$name" "tmux" "starting" "session $session exists; port ${port:-unknown} not listening"
    elif [ -n "$port" ] && port_active "$port"; then
      pid="$(port_pid "$port" || true)"
      if [ -n "$pid" ]; then
        record_listener "$name" "$port" "$pid"
        cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
        printf "%-18s %-8s %-10s %s\n" "$name" "$pid" "running" "${cwd:-port $port listener}"
      else
        record_listener "$name" "$port"
        printf "%-18s %-8s %-10s %s\n" "$name" "-" "running" "port $port listening; pid not visible in this namespace"
      fi
    else
      printf "%-18s %-8s %-10s %s\n" "$name" "tmux" "stale" "$file"
    fi
    continue
  fi

  if pid_alive "$value"; then
    cwd="$(readlink "/proc/$value/cwd" 2>/dev/null || true)"
    printf "%-18s %-8s %-10s %s\n" "$name" "$value" "running" "${cwd:-unknown cwd}"
    continue
  fi

  if [[ "$value" == port:* ]]; then
    port="${value#port:}"
  fi

  if [ -n "$port" ] && port_active "$port"; then
    pid="$(port_pid "$port" || true)"
    if [ -n "$pid" ]; then
      record_listener "$name" "$port" "$pid"
      cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
      printf "%-18s %-8s %-10s %s\n" "$name" "$pid" "running" "${cwd:-port $port listener}"
    else
      record_listener "$name" "$port"
      printf "%-18s %-8s %-10s %s\n" "$name" "-" "running" "port $port listening; pid not visible in this namespace"
    fi
  else
    printf "%-18s %-8s %-10s %s\n" "$name" "${value:-none}" "stale" "$file"
  fi
done
