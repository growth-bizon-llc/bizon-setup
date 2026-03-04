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
  bizon-commerce/     <-- Rails 7 API backend (cloned by setup.sh)
  bizon-admin/        <-- Next.js 15 admin panel (cloned by setup.sh)
```

## Quick Start

```bash
mkdir bizon-projects && cd bizon-projects
git clone https://github.com/growth-bizon-llc/bizon-setup.git
cd bizon-setup
./setup.sh
```

## Scripts

| Script       | Command        | Description                                           |
|--------------|----------------|-------------------------------------------------------|
| `setup.sh`   | `./setup.sh`   | First-time setup: installs everything from scratch    |
| `update.sh`  | `./update.sh`  | Pulls latest, reinstalls deps if needed, restarts     |
| `start.sh`   | `./start.sh`   | Starts both servers and opens the browser             |

### setup.sh

Runs the full setup from zero. Installs prerequisites, clones both repos, installs dependencies, creates and seeds the database, starts the servers, and opens the admin panel.

### update.sh

Pulls the latest changes from both repos and:
1. Stops any running servers on ports 3000/3001
2. `git pull` both repos
3. Reinstalls gems/npm packages only if lock files changed
4. Runs new database migrations if detected
5. Restarts both servers and reopens the browser

### start.sh

Starts both servers without pulling or reinstalling anything. Useful for day-to-day development when you just want to boot the stack.

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

Everything else is installed automatically by `setup.sh`.

## Stopping

Press `Ctrl+C` in the terminal to stop both servers.
