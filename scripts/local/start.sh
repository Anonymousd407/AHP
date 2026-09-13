#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
cd "$ROOT"
mkdir -p "$PIDS"

ensure_free_or_owned() {
  local name="$1" port="$2" remembered existing
  remembered="$(remembered_pid "$name" || true)"
  if pid_alive "$remembered"; then
    echo "$name already running as pid $remembered."
    return 1
  fi

  existing="$(port_pid "$port" || true)"
  if [ -n "$existing" ]; then
    if pid_owned_by_ahp "$existing"; then
      echo "$name port $port is already owned by AHP pid $existing; recording it."
      record_listener "$name" "$port" "$existing"
      return 1
    fi
    echo "Refusing to start $name: port $port is held by non-AHP pid $existing." >&2
    exit 1
  fi

  if port_active "$port"; then
    echo "$name port $port is already listening but its pid is not visible here; recording port-only."
    record_listener "$name" "$port"
    return 1
  fi

  rm -f "$PIDS/$name.pid"
  return 0
}

wait_port() {
  local name="$1" port="$2" pid="${3:-}" session="${4:-}"
  for _ in $(seq 1 80); do
    if port_active "$port"; then
      sleep 1
      port_active "$port" || continue
      local actual
      actual="$(port_pid "$port" || true)"
      if [ -n "$session" ]; then
        record_tmux "$name" "$session"
      elif [ -n "$actual" ]; then
        record_listener "$name" "$port" "$actual"
      else
        record_listener "$name" "$port" "$pid"
      fi
      return 0
    fi
    if [ -n "$pid" ] && ! pid_alive "$pid"; then break; fi
    sleep 0.5
  done
  echo "$name did not open port $port. Last log lines:" >&2
  tail -20 "$LOGS/$name.log" 2>/dev/null || true
  exit 1
}

launch_managed() {
  local name="$1" cmd="$2" session
  session="$(tmux_session_name "$name")"
  if command -v tmux >/dev/null 2>&1; then
    if tmux_alive "$session"; then
      tmux kill-session -t "$session" 2>/dev/null || true
    fi
    tmux new-session -d -s "$session" -c "$ROOT" "$cmd > '$LOGS/$name.log' 2>&1"
    echo "$session"
    return 0
  fi
  nohup setsid bash -lc "$cmd" > "$LOGS/$name.log" 2>&1 < /dev/null &
  echo "$!"
}

start_service() {
  local name="$1" port="${PORT[$1]}" handle
  ensure_free_or_owned "$name" "$port" || return 0
  echo "Starting $name on $port"
  handle="$(launch_managed "$name" "cd 'services/$name' && node --import tsx src/index.ts")"
  if [[ "$handle" == ahp-* ]]; then
    wait_port "$name" "$port" "" "$handle"
  else
    wait_port "$name" "$port" "$handle"
  fi
}

start_app() {
  local label="$1" port pkg handle
  port="${PORT[$label]}"
  pkg="$(app_pkg "$label")"
  ensure_free_or_owned "$label" "$port" || return 0
  echo "Starting $label on $port"
  handle="$(launch_managed "$label" "pnpm --filter '$pkg' dev")"
  if [[ "$handle" == ahp-* ]]; then
    wait_port "$label" "$port" "" "$handle"
  else
    wait_port "$label" "$port" "$handle"
  fi
}

if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'ahealth-pg'; then
  :
elif port_active 5432; then
  echo "Docker status is unavailable, but PostgreSQL is listening on 5432; reusing the existing database listener."
else
  echo "ahealth-pg is not running or PostgreSQL 5432 is not reachable. Start the existing PostgreSQL 16 container before launching AHP." >&2
  exit 1
fi

APPS=("${@:-all}")
if [ "${APPS[0]}" = "all" ]; then APPS=(web-app doctor-app admin-app analytics-app); fi
for i in "${!APPS[@]}"; do
  case "${APPS[$i]}" in
    web) APPS[$i]=web-app ;;
    doctor) APPS[$i]=doctor-app ;;
    admin) APPS[$i]=admin-app ;;
    analytics) APPS[$i]=analytics-app ;;
  esac
done

for svc in "${CORE_SERVICES[@]}"; do start_service "$svc"; done
for app in "${APPS[@]}"; do start_app "$app"; done

echo "AHP local stack is ready."
