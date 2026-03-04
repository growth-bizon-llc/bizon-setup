# Bizon Commerce - Local Setup

One-command setup to run the full Bizon Commerce stack locally on macOS.

## What it does

1. **Installs prerequisites** (if missing): Homebrew, PostgreSQL, rbenv, Ruby 4.0.1, nvm, Node.js
2. **Clones** both repositories as siblings of `bizon-setup`
3. **Installs dependencies** for Rails (bundle install) and Next.js (npm install)
4. **Creates and seeds** the PostgreSQL database with demo data
5. **Starts both servers** and opens the admin panel in your browser

## Project Structure

All scripts expect this directory layout:

```
bizon-projects/
  bizon-setup/        <-- this repo (scripts live here)
  bizon-commerce/     <-- cloned by setup.sh
  bizon-admin/        <-- cloned by setup.sh
```

## Quick Start

```bash
mkdir bizon-projects && cd bizon-projects
git clone https://github.com/growth-bizon-llc/bizon-setup.git
cd bizon-setup
./setup.sh
```

## Updating

Pull latest changes, reinstall dependencies if needed, and restart servers:

```bash
cd bizon-projects/bizon-setup
./update.sh
```

This will:
1. Stop any running servers on ports 3000/3001
2. `git pull` both repos
3. Reinstall gems/npm packages only if lock files changed
4. Run new database migrations if any
5. Restart both servers and reopen the browser

## Starting

Start both servers without pulling or reinstalling anything:

```bash
cd bizon-projects/bizon-setup
./start.sh
```

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

Everything else is installed automatically by the setup script.

## Stopping

Press `Ctrl+C` in the terminal to stop both servers.
