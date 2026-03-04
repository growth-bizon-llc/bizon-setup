# Bizon Commerce - Local Setup

One-command setup to run the full Bizon Commerce stack locally on macOS.

## What it does

1. **Installs prerequisites** (if missing): Homebrew, PostgreSQL, rbenv, Ruby 4.0.1, nvm, Node.js
2. **Clones** both repositories from GitHub
3. **Installs dependencies** for Rails (bundle install) and Next.js (npm install)
4. **Creates and seeds** the PostgreSQL database with demo data
5. **Starts both servers** and opens the admin panel in your browser

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/growth-bizon-llc/bizon-setup/main/setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

Or clone this repo first:

```bash
git clone https://github.com/growth-bizon-llc/bizon-setup.git
cd bizon-setup
chmod +x setup.sh
./setup.sh
```

## Updating

To pull the latest changes, reinstall dependencies if needed, and restart the servers:

```bash
curl -fsSL https://raw.githubusercontent.com/growth-bizon-llc/bizon-setup/main/update.sh -o update.sh
chmod +x update.sh
./update.sh
```

Or if you already cloned the repo:

```bash
cd bizon-setup
./update.sh
```

This will:
1. Stop any running servers on ports 3000/3001
2. `git pull` both repos
3. Reinstall gems/npm packages only if lock files changed
4. Run new database migrations if any
5. Restart both servers and reopen the browser

## Services

| Service       | URL                          | Description             |
|---------------|------------------------------|-------------------------|
| Rails API     | http://localhost:3000         | Backend API             |
| Admin Panel   | http://localhost:3001         | Next.js admin dashboard |

## Default Login

| Email              | Password      | Role  |
|--------------------|---------------|-------|
| owner@demo.com     | password123   | Owner |
| admin@demo.com     | password123   | Admin |
| staff@demo.com     | password123   | Staff |

## Requirements

- macOS (Apple Silicon or Intel)
- Git

Everything else is installed automatically by the script.

## Stopping

Press `Ctrl+C` in the terminal to stop both servers.
