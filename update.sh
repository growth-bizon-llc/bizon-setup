#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bizon Commerce - Update & Restart
# ============================================================================
# Pulls latest changes for both repos, reinstalls dependencies if needed,
# runs migrations, and restarts servers.
#
# Usage:
#   ./update.sh
#
# Ports:
#   - bizon-commerce (Rails API): http://localhost:3000
#   - bizon-admin (Next.js):      http://localhost:3001
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

# ============================================================================
# Validate repos exist
# ============================================================================

if [ ! -d "$REPOS_DIR/bizon-commerce" ] || [ ! -d "$REPOS_DIR/bizon-admin" ]; then
  error "Repos not found in $REPOS_DIR. Run setup.sh first."
fi

echo ""
echo -e "${BOLD}=====================================${NC}"
echo -e "${BOLD}  Bizon Commerce - Update & Restart${NC}"
echo -e "${BOLD}=====================================${NC}"
echo ""

# ============================================================================
# 1. Stop running servers
# ============================================================================

log "Stopping any running servers..."

RAILS_RUNNING=false
NEXT_RUNNING=false

if lsof -ti :"$RAILS_PORT" &>/dev/null; then
  RAILS_RUNNING=true
  warn "Killing process on port ${RAILS_PORT}..."
  kill $(lsof -ti :"$RAILS_PORT") 2>/dev/null || true
  sleep 1
fi

if lsof -ti :"$NEXT_PORT" &>/dev/null; then
  NEXT_RUNNING=true
  warn "Killing process on port ${NEXT_PORT}..."
  kill $(lsof -ti :"$NEXT_PORT") 2>/dev/null || true
  sleep 1
fi

if [ "$RAILS_RUNNING" = false ] && [ "$NEXT_RUNNING" = false ]; then
  log "No servers were running."
fi

# ============================================================================
# 2. Pull latest changes
# ============================================================================

log "Pulling bizon-commerce..."
COMMERCE_OUTPUT=$(git -C "$REPOS_DIR/bizon-commerce" pull --ff-only 2>&1)
echo "  $COMMERCE_OUTPUT"

log "Pulling bizon-admin..."
ADMIN_OUTPUT=$(git -C "$REPOS_DIR/bizon-admin" pull --ff-only 2>&1)
echo "  $ADMIN_OUTPUT"

# ============================================================================
# 3. Reinstall dependencies if lock files changed
# ============================================================================

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

cd "$REPOS_DIR/bizon-commerce"

if echo "$COMMERCE_OUTPUT" | grep -q "Gemfile.lock"; then
  log "Gemfile.lock changed — reinstalling gems..."
  bundle install
else
  success "Gems up to date."
fi

if echo "$COMMERCE_OUTPUT" | grep -qE "db/migrate"; then
  log "New migrations detected — running db:migrate..."
  bin/rails db:migrate
else
  success "Database schema up to date."
fi

cd "$REPOS_DIR/bizon-admin"

if echo "$ADMIN_OUTPUT" | grep -q "package-lock.json"; then
  log "package-lock.json changed — reinstalling npm packages..."
  npm install
else
  success "npm packages up to date."
fi

# ============================================================================
# 4. Restart servers
# ============================================================================

echo ""
echo -e "${BOLD}=====================================${NC}"
echo -e "${BOLD}  Restarting servers...${NC}"
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

log "Opening bizon-admin in your browser..."
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
