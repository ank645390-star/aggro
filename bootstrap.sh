#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# TAMIS АГРО — one-shot bootstrap script
#
# What it does:
#   1. Verifies the required toolchain (Python 3.11+, Node 18+, Yarn, Mongo)
#   2. Creates .env files from the .env.example templates if missing
#   3. Installs backend Python dependencies into a local virtualenv
#   4. Installs frontend JS dependencies via yarn
#   5. Optionally seeds the database with demo content
#   6. Prints next-step commands to start the dev servers
#
# Usage:
#   chmod +x bootstrap.sh
#   ./bootstrap.sh                 # full setup
#   ./bootstrap.sh --skip-frontend # backend only
#   ./bootstrap.sh --skip-backend  # frontend only
#   ./bootstrap.sh --reset-env     # overwrite existing .env files
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────
RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; BLU=$'\033[34m'; NC=$'\033[0m'
log()   { printf "%s[bootstrap]%s %s\n" "$BLU" "$NC" "$*"; }
ok()    { printf "%s[ ok ]%s     %s\n"  "$GRN" "$NC" "$*"; }
warn()  { printf "%s[warn]%s     %s\n"  "$YLW" "$NC" "$*"; }
fail()  { printf "%s[fail]%s     %s\n"  "$RED" "$NC" "$*" >&2; exit 1; }

# ── Args ─────────────────────────────────────────────────────────────────
SKIP_BACKEND=0; SKIP_FRONTEND=0; RESET_ENV=0
for arg in "$@"; do
  case "$arg" in
    --skip-backend)  SKIP_BACKEND=1 ;;
    --skip-frontend) SKIP_FRONTEND=1 ;;
    --reset-env)     RESET_ENV=1 ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) warn "Unknown flag: $arg (ignored)" ;;
  esac
done

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# ── 1. Toolchain checks ──────────────────────────────────────────────────
log "Verifying toolchain"
command -v python3 >/dev/null || fail "python3 not found (need 3.11+)"
command -v node    >/dev/null || fail "node not found (need 18+)"
command -v yarn    >/dev/null || fail "yarn not found — install with: npm i -g yarn"
command -v mongod  >/dev/null || warn "mongod binary not found in PATH — make sure MongoDB is reachable via MONGO_URL"

PY_VER=$(python3 -c 'import sys;print("%d.%d"%sys.version_info[:2])')
NODE_VER=$(node -v | sed 's/^v//' | cut -d. -f1)
[[ "$(printf '%s\n3.11\n' "$PY_VER" | sort -V | head -1)" == "3.11" ]] \
  || warn "Python $PY_VER detected — 3.11+ recommended"
[[ "$NODE_VER" -ge 18 ]] || warn "Node $NODE_VER detected — 18+ recommended"
ok "Toolchain: python=$PY_VER, node=v$NODE_VER, yarn=$(yarn -v)"

# ── 2. .env files ────────────────────────────────────────────────────────
maybe_copy_env() {
  local src="$1" dst="$2"
  if [[ -f "$dst" && "$RESET_ENV" -eq 0 ]]; then
    ok "$dst already exists (keep). Use --reset-env to overwrite."
  else
    cp "$src" "$dst"
    ok "Created $dst from template — edit it before going to production!"
  fi
}

log "Preparing .env files"
maybe_copy_env backend/.env.example  backend/.env
maybe_copy_env frontend/.env.example frontend/.env

# ── 3. Backend deps ──────────────────────────────────────────────────────
if [[ "$SKIP_BACKEND" -eq 0 ]]; then
  log "Installing backend dependencies (this may take a few minutes…)"
  cd "$ROOT/backend"
  if [[ ! -d .venv ]]; then
    python3 -m venv .venv
    ok "Created backend/.venv"
  fi
  # shellcheck disable=SC1091
  source .venv/bin/activate
  pip install --quiet --upgrade pip
  pip install --quiet -r requirements.txt
  deactivate
  ok "Backend dependencies installed"
  cd "$ROOT"
else
  warn "Skipping backend setup (--skip-backend)"
fi

# ── 4. Frontend deps ─────────────────────────────────────────────────────
if [[ "$SKIP_FRONTEND" -eq 0 ]]; then
  log "Installing frontend dependencies via yarn"
  cd "$ROOT/frontend"
  yarn install --silent
  ok "Frontend dependencies installed"
  cd "$ROOT"
else
  warn "Skipping frontend setup (--skip-frontend)"
fi

# ── 5. Done ──────────────────────────────────────────────────────────────
cat <<EOF

${GRN}╭──────────────────────────────────────────────────────────────╮${NC}
${GRN}│${NC}  TAMIS АГРО is ready. Start the dev servers:                 ${GRN}│${NC}
${GRN}├──────────────────────────────────────────────────────────────┤${NC}
${GRN}│${NC}  Terminal 1 — backend:                                       ${GRN}│${NC}
${GRN}│${NC}    cd backend && source .venv/bin/activate \\                 ${GRN}│${NC}
${GRN}│${NC}      && uvicorn server:app --host 0.0.0.0 --port 8001 --reload${GRN}│${NC}
${GRN}│${NC}                                                              ${GRN}│${NC}
${GRN}│${NC}  Terminal 2 — frontend:                                      ${GRN}│${NC}
${GRN}│${NC}    cd frontend && yarn start                                 ${GRN}│${NC}
${GRN}│${NC}                                                              ${GRN}│${NC}
${GRN}│${NC}  Open the app:  http://localhost:3000                        ${GRN}│${NC}
${GRN}│${NC}  Demo creds:    test@tamis.ua / test1234  (customer)         ${GRN}│${NC}
${GRN}│${NC}                 admin@tamis.ua / admin1234 (admin)           ${GRN}│${NC}
${GRN}╰──────────────────────────────────────────────────────────────╯${NC}
EOF
