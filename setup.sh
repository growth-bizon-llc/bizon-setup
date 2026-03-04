#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bizon Commerce - Local Development Setup
# ============================================================================
# This script clones, installs, and runs both bizon-commerce (Rails API) and
# bizon-admin (Next.js admin panel) for local development on macOS.
#
# Usage:
#   chmod +x setup.sh && ./setup.sh
#
# Ports:
#   - bizon-commerce (Rails API): http://localhost:3000
#   - bizon-admin (Next.js):      http://localhost:3001
#
# Default login: owner@demo.com / password123
# ============================================================================

RUBY_REQUIRED="4.0.1"
NODE_MINIMUM="18"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="$(dirname "$SCRIPT_DIR")"
RAILS_PORT=3000
NEXT_PORT=3001
ORG="growth-bizon-llc"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()    { echo -e "${BLUE}[bizon]${NC} $1"; }
success(){ echo -e "${GREEN}[bizon]${NC} $1"; }
warn()   { echo -e "${YELLOW}[bizon]${NC} $1"; }
error()  { echo -e "${RED}[bizon]${NC} $1"; }

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
# 1. Prerequisites
# ============================================================================

echo ""
echo -e "${BOLD}=====================================${NC}"
echo -e "${BOLD}  Bizon Commerce - Local Setup${NC}"
echo -e "${BOLD}=====================================${NC}"
echo ""

# -- Homebrew --
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  success "Homebrew installed."
else
  success "Homebrew found."
fi

# -- PostgreSQL --
if ! command -v psql &>/dev/null; then
  log "Installing PostgreSQL via Homebrew..."
  brew install postgresql@17
  brew services start postgresql@17
  sleep 3
  success "PostgreSQL installed and started."
else
  success "PostgreSQL found."
  if ! brew services list 2>/dev/null | grep -q "postgresql.*started"; then
    log "Starting PostgreSQL..."
    brew services start postgresql@17 2>/dev/null || brew services start postgresql 2>/dev/null || true
    sleep 2
  fi
fi

# -- rbenv + Ruby --
if ! command -v rbenv &>/dev/null; then
  log "Installing rbenv via Homebrew..."
  brew install rbenv ruby-build
  eval "$(rbenv init - bash)"
  success "rbenv installed."
else
  success "rbenv found."
  eval "$(rbenv init - bash)" 2>/dev/null || true
fi

if ! rbenv versions --bare 2>/dev/null | grep -q "^${RUBY_REQUIRED}$"; then
  log "Installing Ruby ${RUBY_REQUIRED} (this may take a few minutes)..."
  rbenv install "$RUBY_REQUIRED"
  success "Ruby ${RUBY_REQUIRED} installed."
else
  success "Ruby ${RUBY_REQUIRED} found."
fi

# -- nvm + Node.js --
export NVM_DIR="${HOME}/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
fi

if ! command -v nvm &>/dev/null; then
  if ! command -v node &>/dev/null; then
    log "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="${HOME}/.nvm"
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
    log "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    success "Node.js installed via nvm."
  else
    NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VERSION" -ge "$NODE_MINIMUM" ]; then
      success "Node.js $(node -v) found."
    else
      error "Node.js >= ${NODE_MINIMUM} required, found $(node -v)."
      log "Installing nvm and Node.js LTS..."
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
      export NVM_DIR="${HOME}/.nvm"
      # shellcheck disable=SC1091
      source "$NVM_DIR/nvm.sh"
      nvm install --lts
      nvm use --lts
      success "Node.js LTS installed."
    fi
  fi
else
  if ! command -v node &>/dev/null; then
    log "Installing Node.js LTS via nvm..."
    nvm install --lts
    nvm use --lts
  else
    success "Node.js $(node -v) found."
  fi
fi

# -- Bundler --
if ! gem list bundler -i &>/dev/null; then
  log "Installing Bundler..."
  gem install bundler
fi

echo ""
success "All prerequisites are ready!"
echo ""

# ============================================================================
# 2. Clone repositories
# ============================================================================

if [ ! -d "$REPOS_DIR/bizon-commerce" ]; then
  log "Cloning bizon-commerce..."
  git clone "https://github.com/${ORG}/bizon-commerce.git" "$REPOS_DIR/bizon-commerce"
  success "bizon-commerce cloned."
else
  warn "bizon-commerce already exists, pulling latest..."
  git -C "$REPOS_DIR/bizon-commerce" pull --ff-only || true
fi

if [ ! -d "$REPOS_DIR/bizon-admin" ]; then
  log "Cloning bizon-admin..."
  git clone "https://github.com/${ORG}/bizon-admin.git" "$REPOS_DIR/bizon-admin"
  success "bizon-admin cloned."
else
  warn "bizon-admin already exists, pulling latest..."
  git -C "$REPOS_DIR/bizon-admin" pull --ff-only || true
fi

# ============================================================================
# 3. Setup bizon-commerce (Rails API)
# ============================================================================

echo ""
log "Setting up bizon-commerce (Rails API)..."
cd "$REPOS_DIR/bizon-commerce"

rbenv local "$RUBY_REQUIRED"
eval "$(rbenv init - bash)" 2>/dev/null || true

log "Installing Ruby gems..."
bundle install

log "Creating database..."
bin/rails db:create 2>/dev/null || warn "Database may already exist, continuing..."

log "Running migrations..."
bin/rails db:migrate

log "Seeding database..."
bin/rails db:seed

success "bizon-commerce is ready!"

# ============================================================================
# 4. Setup bizon-admin (Next.js)
# ============================================================================

echo ""
log "Setting up bizon-admin (Next.js)..."
cd "$REPOS_DIR/bizon-admin"

log "Installing npm dependencies..."
npm install

# Create .env.local pointing to local Rails API
cat > .env.local <<EOF
NEXT_PUBLIC_API_URL=http://localhost:${RAILS_PORT}/api/v1
EOF

success "bizon-admin is ready!"

# ============================================================================
# 5. Start servers
# ============================================================================

echo ""
echo -e "${BOLD}=====================================${NC}"
echo -e "${BOLD}  Starting servers...${NC}"
echo -e "${BOLD}=====================================${NC}"
echo ""

# Start Rails API
cd "$REPOS_DIR/bizon-commerce"
log "Starting Rails API on port ${RAILS_PORT}..."
bin/rails server -p "$RAILS_PORT" &
RAILS_PID=$!

# Start Next.js
cd "$REPOS_DIR/bizon-admin"
log "Starting Next.js on port ${NEXT_PORT}..."
npx next dev -p "$NEXT_PORT" &
NEXT_PID=$!

# Wait for Next.js to be ready
log "Waiting for servers to start..."
sleep 8

# Open browser
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

# Keep script running until Ctrl+C
wait
