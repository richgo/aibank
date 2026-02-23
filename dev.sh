#!/usr/bin/env bash
# dev.sh — Start all AIBank services in debug/development mode
# Usage: ./dev.sh [--no-mcp] [--no-flutter] [--no-map-server]
#
# Services started:
#   Agent      → http://localhost:8080  (uvicorn --reload)
#   MCP        → http://localhost:5173  (MCP Inspector UI for bank tools)
#   Map server → http://localhost:3001  (OSM/Nominatim geocoding via MCP)
#   Flutter    → http://localhost:3000  (web-server debug build)
#
# The map server is @modelcontextprotocol/server-map — free, no API key needed.
# It is started with MAP_SERVER_URL exported so the agent picks it up.
#
# Logs are written to .dev-logs/
# Press Ctrl+C to stop everything.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$REPO_ROOT/.dev-logs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

START_MCP=true
START_MAP_SERVER=true
START_FLUTTER=true
CLEANED_UP=false

for arg in "$@"; do
  case $arg in
    --no-mcp)        START_MCP=false ;;
    --no-map-server) START_MAP_SERVER=false ;;
    --no-flutter)    START_FLUTTER=false ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────

log()  { echo -e "${CYAN}[dev]${NC} $*"; }
ok()   { echo -e "${GREEN}[dev]${NC} $*"; }
warn() { echo -e "${YELLOW}[dev]${NC} $*"; }
err()  { echo -e "${RED}[dev]${NC} $*" >&2; }

pid_file() { echo "$LOGS_DIR/$1.pid"; }

store_pid() {
  local name=$1 pid=$2
  echo "$pid" > "$(pid_file "$name")"
}

kill_service() {
  local name=$1
  local port=${2:-}
  local pf
  pf="$(pid_file "$name")"
  if [[ -f "$pf" ]]; then
    local pid
    pid="$(cat "$pf")"
    if [[ -n "$pid" ]]; then
      stop_pid_tree "$pid"
    fi
    rm -f "$pf"
  fi
  [[ -n "$port" ]] && kill_port_processes "$name" "$port"
}

child_pids() {
  local pid=$1
  ps -o pid= --ppid "$pid" 2>/dev/null | tr -d ' '
}

kill_pid_tree_term() {
  local pid=$1
  local child
  for child in $(child_pids "$pid"); do
    kill_pid_tree_term "$child"
  done
  kill "$pid" 2>/dev/null || true
}

kill_pid_tree_kill() {
  local pid=$1
  local child
  for child in $(child_pids "$pid"); do
    kill_pid_tree_kill "$child"
  done
  kill -9 "$pid" 2>/dev/null || true
}

stop_pid_tree() {
  local pid=$1
  kill_pid_tree_term "$pid"
  sleep 1
  if kill -0 "$pid" 2>/dev/null; then
    kill_pid_tree_kill "$pid"
  fi
}

kill_port_processes() {
  local name=$1
  local port=$2
  local pids
  pids="$(port_pids "$port" || true)"
  [[ -z "$pids" ]] && return 0

  local pid
  for pid in $pids; do
    local cmd
    cmd="$(ps -p "$pid" -o cmd= 2>/dev/null || true)"
    warn "Stopping $name process on :$port (pid $pid, cmd: ${cmd:-<unknown>})"
    stop_pid_tree "$pid"
  done
}

port_pids() {
  local port=$1
  ss -ltnp 2>/dev/null \
    | grep ":$port " \
    | grep -o 'pid=[0-9]\+' \
    | cut -d= -f2 \
    | sort -u
}

ensure_port_available_for() {
  local name=$1
  local port=$2
  kill_port_processes "$name" "$port"

  local pids
  pids="$(port_pids "$port" || true)"
  [[ -z "$pids" ]] && return 0

  local pid
  for pid in $pids; do
    local cmd
    cmd="$(ps -p "$pid" -o cmd= 2>/dev/null || true)"
    err "Port :$port still in use by pid $pid after shutdown attempt"
    err "Command: ${cmd:-<unknown>}"
  done
  exit 1
}

wait_for_http() {
  local name=$1 url=$2 retries=${3:-30}
  log "Waiting for $name at $url ..."
  for i in $(seq 1 "$retries"); do
    if curl -sf "$url" -o /dev/null 2>/dev/null; then
      ok "$name is up"
      return 0
    fi
    sleep 1
  done
  warn "$name did not respond after ${retries}s — check .dev-logs/${name}.log"
  return 1
}

cleanup() {
  if $CLEANED_UP; then
    return
  fi
  CLEANED_UP=true

  echo ""
  warn "Shutting down all services..."
  kill_service flutter 3000
  kill_service map-server 3001
  kill_service mcp 5173
  kill_service agent 8080
  ok "Done."
}

trap cleanup EXIT INT TERM

# ── Preflight ─────────────────────────────────────────────────────────────────

mkdir -p "$LOGS_DIR"

if ! command -v python3 &>/dev/null; then
  err "python3 not found. Please install Python 3.10+."
  exit 1
fi

if ! python3 -c "import uvicorn" 2>/dev/null; then
  err "uvicorn not installed. Run: pip install -r agent/requirements.txt"
  exit 1
fi

# Locate flutter — prefer snap install used on this machine
FLUTTER_BIN=""
for candidate in flutter /snap/bin/flutter "$HOME/snap/flutter/common/flutter/bin/flutter"; do
  if command -v "$candidate" &>/dev/null 2>&1; then
    FLUTTER_BIN="$candidate"
    break
  fi
done

if [[ -z "$FLUTTER_BIN" ]] && $START_FLUTTER; then
  warn "flutter not found — skipping Flutter (use --no-flutter to suppress this warning)"
  START_FLUTTER=false
fi

# ── Map server ────────────────────────────────────────────────────────────────
# @modelcontextprotocol/server-map: CesiumJS 3D globe + OSM Nominatim geocoding
# No API key required. Runs HTTP mode on port 3001 at /mcp.

if $START_MAP_SERVER; then
  if ! command -v npx &>/dev/null; then
    warn "npx not found — skipping map server (install Node.js to enable map features)"
    START_MAP_SERVER=false
  else
    ensure_port_available_for map-server 3001
    log "Starting map server on :3001 ..."
    cd "$REPO_ROOT"
    PORT=3001 npx -y --silent "@modelcontextprotocol/server-map" \
      > "$LOGS_DIR/map-server.log" 2>&1 &
    store_pid map-server $!
    # Export so the agent picks up the URL automatically
    export MAP_SERVER_URL="http://localhost:3001/mcp"
    # Give npx a moment to download and start
    sleep 3
    ok "Map server started (MAP_SERVER_URL=$MAP_SERVER_URL)"
  fi
fi

# ── Agent ─────────────────────────────────────────────────────────────────────

ensure_port_available_for agent 8080
log "Starting agent (uvicorn --reload) on :8080 ..."
cd "$REPO_ROOT"
python3 -m uvicorn agent.agent:app \
  --host 0.0.0.0 --port 8080 \
  --reload \
  > "$LOGS_DIR/agent.log" 2>&1 &
store_pid agent $!
wait_for_http agent "http://localhost:8080/health"

# ── MCP Inspector (bank tools) ────────────────────────────────────────────────

if $START_MCP; then
  if ! command -v mcp &>/dev/null; then
    warn "'mcp' CLI not found. Install with: pip install 'mcp[cli]'"
    warn "Skipping MCP inspector."
    START_MCP=false
  else
    ensure_port_available_for mcp 5173
    log "Starting MCP inspector on :5173 ..."
    cd "$REPO_ROOT"
    mcp dev mcp_server/mcp_server.py \
      > "$LOGS_DIR/mcp.log" 2>&1 &
    store_pid mcp $!
    sleep 2
    ok "MCP inspector started (check .dev-logs/mcp.log for URL)"
  fi
fi

# ── Flutter web ───────────────────────────────────────────────────────────────

if $START_FLUTTER; then
  "$FLUTTER_BIN" config --enable-web --quiet 2>/dev/null || true

  ensure_port_available_for flutter 3000
  log "Starting Flutter web on :3000 (debug build) ..."
  cd "$REPO_ROOT/app"
  "$FLUTTER_BIN" run \
    --device-id web-server \
    --web-port 3000 \
    --debug \
    > "$LOGS_DIR/flutter.log" 2>&1 &
  store_pid flutter $!
  wait_for_http flutter "http://localhost:3000"
  cd "$REPO_ROOT"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}AIBank dev environment running${NC}"
echo "  Agent:      http://localhost:8080"
if $START_MAP_SERVER; then echo "  Map server: http://localhost:3001  (geocoding MCP — MAP_SERVER_URL set)"; fi
if $START_MCP;        then echo "  MCP:        http://localhost:5173  (bank tools Inspector UI)"; fi
if $START_FLUTTER;    then echo "  Flutter:    http://localhost:3000"; fi
echo ""
echo "Logs:"
echo "  tail -f $LOGS_DIR/agent.log"
if $START_MAP_SERVER; then echo "  tail -f $LOGS_DIR/map-server.log"; fi
if $START_MCP;        then echo "  tail -f $LOGS_DIR/mcp.log"; fi
if $START_FLUTTER;    then echo "  tail -f $LOGS_DIR/flutter.log"; fi
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services.${NC}"

wait
