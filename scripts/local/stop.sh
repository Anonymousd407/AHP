#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

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
    if tmux_alive "$session"; then
      echo "Stopping $name tmux session $session"
      tmux kill-session -t "$session" 2>/dev/null || true
    elif [ -n "$port" ] && port_active "$port"; then
      echo "Leaving $name on port $port running: tmux session is gone and listener pid is not visible in this namespace."
      record_listener "$name" "$port" "$(port_pid "$port" || true)"
    else
      echo "Removing stale tmux pid for $name."
      rm -f "$file"
    fi
    continue
  fi

  if [[ "$value" == port:* ]]; then
    port="${value#port:}"
    value=""
  fi

  if ! pid_alive "$value" && [ -n "$port" ]; then
    value="$(port_pid "$port" || true)"
  fi

  if [ -z "$value" ] || ! pid_alive "$value"; then
    if [ -n "$port" ] && port_active "$port"; then
      echo "Leaving $name on port $port running: listener pid is not visible in this namespace."
      record_listener "$name" "$port"
    else
      echo "Removing stale pid for $name."
      rm -f "$file"
    fi
    continue
  fi

  if ! pid_owned_by_ahp "$value"; then
    echo "Refusing to stop $name pid $value: process is not AHP-owned." >&2
    continue
  fi

  echo "Stopping $name pid $value"
  kill "$value" 2>/dev/null || true
done

sleep 1

for file in "$PIDS"/*.pid; do
  [ -e "$file" ] || continue
  name="$(basename "$file" .pid)"
  value="$(sed -n '1p' "$file")"
  port="$(name_port "$name")"
  if [[ "$value" == tmux:* ]]; then
    tmux_alive "${value#tmux:}" || rm -f "$file"
    continue
  fi
  [[ "$value" == port:* ]] && port="${value#port:}" && value=""

  if pid_alive "$value"; then
    continue
  fi
  if [ -n "$port" ] && port_active "$port"; then
    record_listener "$name" "$port" "$(port_pid "$port" || true)"
  else
    rm -f "$file"
  fi
done
