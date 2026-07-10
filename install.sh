#!/usr/bin/env bash
# Reproduce my preferred Claude Code setup on a fresh machine.
# Idempotent: safe to re-run. Reads secrets from env (see .env.example).
#
#   cp .env.example .env && $EDITOR .env && set -a && . ./.env && set +a && ./install.sh
#
# ponytail:  CLI + skills over MCP; MCP only where there's no CLI equivalent
#            (context7, exa, github). jina is a local skill, not an MCP.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

have claude || { echo "claude CLI not found. Install Claude Code first: https://docs.claude.com/en/docs/claude-code"; exit 1; }

# ── Marketplaces (idempotent: `add` no-ops if already present) ───────────────
log "Adding marketplaces"
claude plugin marketplace add obra/superpowers-marketplace  2>/dev/null || true
claude plugin marketplace add Yeachan-Heo/oh-my-claudecode  2>/dev/null || true
claude plugin marketplace add DietrichGebert/ponytail        2>/dev/null || true
claude plugin marketplace add thedotmack/claude-mem          2>/dev/null || true

# ── Plugins (bar is set to OMC) ──────────────────────────────────────────────
log "Installing plugins"
claude plugin install superpowers@superpowers-marketplace
claude plugin install claude-mem@thedotmack
claude plugin install oh-my-claudecode@omc
claude plugin install ponytail@ponytail 

# ── MCP servers: only what has no good CLI/skill path ────────────────────────
# Scope = user so they apply everywhere. `add` errors if the name exists; ignore.
# GitHub is intentionally NOT here — the `gh` CLI covers it.
log "Configuring MCP servers (context7, exa)"
: "${CONTEXT7_API_KEY:?set CONTEXT7_API_KEY (see .env.example)}"
: "${EXA_API_KEY:?set EXA_API_KEY}"

claude mcp add -s user context7 -- \
  npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY" 2>/dev/null || true
claude mcp add -s user exa -e "EXA_API_KEY=$EXA_API_KEY" -- \
  npx -y exa-mcp-server 2>/dev/null || true

# ── Shared config: CLAUDE.md + rules (symlinked, backs up existing) ──────────
log "Linking shared Claude config"
"$REPO/claude/link.sh"

# ── Skills (jina-reader — local, private WebFetch replacement) ───────────────
log "Installing jina-reader skill"
mkdir -p "$CLAUDE_DIR/skills"
cp -R "$REPO/skills/jina-reader" "$CLAUDE_DIR/skills/jina-reader"

# ── jina Reader local stack (docker via colima) ──────────────────────────────
# ponytail: skip if you don't need web fetch/screenshots. The skill degrades to
# an error if localhost:3333 is down — install it only when you want fetch.
if [ "${SKIP_JINA:-0}" != "1" ]; then
  log "Setting up jina-ai local Reader"
  "$REPO/jina-ai/setup-jina.sh"
fi

# ── OTel telemetry collector (optional) ──────────────────────────────────────
# Reuses the jina-ai colima profile. Enable exporting via OTEL_* env in
# ~/.claude/settings.json (machine-local). See monitoring/README.md.
if [ "${SKIP_OTEL:-0}" != "1" ]; then
  log "Setting up OTel collector"
  "$REPO/monitoring/setup-otel.sh"
fi

log "Done. Restart Claude Code to load plugins. Verify: claude plugin list"
