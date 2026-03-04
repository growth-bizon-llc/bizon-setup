#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bizon Commerce - Start Servers
# ============================================================================
# Starts both servers assuming repos are already cloned and set up.
#
# Usage:
#   ./start.sh
# ============================================================================

REPOS_DIR="$(pwd)/bizon-projects"
RAILS_PORT=3000
NEXT_PORT=3001

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()    { echo -e "${BLUE}[bizon]${NC} $1"; }
success(){ echo -e "${GREEN}[bizon]${NC} $1"; }
warn()   { echo -e "${YELLOW}[bizon]${NC} $1"; }
error()  { echo -e "${RED}[bizon]${NC} $1"; exit 1; }

cleanup() {
  log "Shutting down servers..."
  if [ -n "${RAILS_PID:-}" ] && kill -0 "$RAILS_PID" 2>/dev/null; then
    kill "$RAILS_PID" 2>/dev/null || true
  fi
  if [ -n "${NEXT_PID:-}" ] && kill -0 "$NEXT_PID" 2>/dev/null; then
    kill "$NEXT_PID" 2>/dev/null || true
  fi
  success "Servers stopped. Goodbye!"
}
trap cleanup EXIT INT TERM

if [ ! -d "$REPOS_DIR/bizon-commerce" ] || [ ! -d "$REPOS_DIR/bizon-admin" ]; then
  error "Repos not found in $REPOS_DIR. Run setup.sh first."
fi

# Load rbenv
if command -v rbenv &>/dev/null; then
  eval "$(rbenv init - bash)" 2>/dev/null || true
fi

# Load nvm
export NVM_DIR="${HOME}/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
fi

# Kill anything already on those ports
if lsof -ti :"$RAILS_PORT" &>/dev/null; then
  warn "Killing existing process on port ${RAILS_PORT}..."
  kill $(lsof -ti :"$RAILS_PORT") 2>/dev/null || true
  sleep 1
fi
if lsof -ti :"$NEXT_PORT" &>/dev/null; then
  warn "Killing existing process on port ${NEXT_PORT}..."
  kill $(lsof -ti :"$NEXT_PORT") 2>/dev/null || true
  sleep 1
fi

echo ""
echo -e "${BOLD}=====================================${NC}"
echo -e "${BOLD}  Starting Bizon Commerce...${NC}"
echo -e "${BOLD}=====================================${NC}"
echo ""

cd "$REPOS_DIR/bizon-commerce"
log "Starting Rails API on port ${RAILS_PORT}..."
bin/rails server -p "$RAILS_PORT" &
RAILS_PID=$!

cd "$REPOS_DIR/bizon-admin"
log "Starting Next.js on port ${NEXT_PORT}..."
npx next dev -p "$NEXT_PORT" &
NEXT_PID=$!

sleep 6

open "http://localhost:${NEXT_PORT}"

echo ""
echo -e "${BOLD}=====================================${NC}"
echo -e "${GREEN}${BOLD}  Bizon Commerce is running!${NC}"
echo -e "${BOLD}=====================================${NC}"
echo ""
echo -e "  ${BOLD}Rails API:${NC}     http://localhost:${RAILS_PORT}"
echo -e "  ${BOLD}Admin Panel:${NC}   http://localhost:${NEXT_PORT}"
echo ""
echo -e "  ${BOLD}Login:${NC}         owner@demo.com / password123"
echo ""
echo -e "  Press ${BOLD}Ctrl+C${NC} to stop both servers."
echo ""

wait
