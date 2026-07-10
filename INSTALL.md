# Installation Guide — for an LLM agent

You are an AI coding agent (Claude Code, etc.) setting up this machine with the
owner's preferred Claude Code stack. Follow these steps in order. Stop and ask
the human only where told to. Be lazy: skip steps already satisfied.

**Repo:** `ZebaLive/claude-in-a-box` (raw base:
`https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/`)

## 0. Preconditions — check, don't assume

Run these and report what's missing before proceeding:

```sh
command -v claude || echo "MISSING: Claude Code CLI — https://docs.claude.com/en/docs/claude-code"
command -v git colima docker || echo "MISSING one of: git colima docker (brew install colima docker docker-compose)"
uname -s   # expect Darwin; the jina + otel local stacks are macOS/colima-only
```

If Claude Code or git is missing, stop and tell the human to install them first.
If only colima/docker is missing, you may continue but must set `SKIP_JINA=1
SKIP_OTEL=1` (the local docker stacks will be skipped).

## 1. Clone the repo

```sh
DIR="$HOME/Development/claude-setups"
[ -d "$DIR/.git" ] || git clone https://github.com/ZebaLive/claude-in-a-box.git "$DIR"
cd "$DIR"
```

## 2. Collect secrets — ASK THE HUMAN

`install.sh` needs API keys. Do **not** invent them. Create `.env` from the
template, then ask the human for each value and fill it in:

```sh
cp -n .env.example .env
```

Ask the human for:
- `EXA_API_KEY` — from https://exa.ai
- `CONTEXT7_API_KEY` — from https://context7.com — **optional**, only raises `ctx7` CLI rate limits. Leave blank if they don't have one.

Write their answers into `.env`. A blank `EXA_API_KEY` means the exa MCP server
won't configure; a blank `CONTEXT7_API_KEY` is fine (the `ctx7` CLI just runs at
default rate limits). The rest still installs.

## 3. Run the installer

```sh
set -a && . ./.env && set +a
./install.sh
```

Optional env flags (set before running if the situation calls for it):
- `SKIP_JINA=1` — skip the local jina Reader docker stack (no web-fetch skill backend)
- `SKIP_OTEL=1` — skip the OTel telemetry collector

What `install.sh` does (for your awareness — don't re-do it by hand):
- Adds marketplaces + installs plugins: superpowers, oh-my-claudecode, ponytail, claude-mem
- Configures the exa MCP server (context7 = `ctx7` CLI + rule, github = `gh` CLI — neither is an MCP)
- Symlinks `claude/CLAUDE.md` and `claude/rules/` into `~/.claude` (backs up existing to `.bak`)
- Installs the `jina-reader` skill
- Brings up local docker stacks: jina Reader (`localhost:3333`), OTel collector

## 4. Machine-local settings — the parts NOT in the repo

The repo deliberately omits `~/.claude/settings.json` (per-machine: cloud
provider, permission allowlist, telemetry env). If the human wants telemetry
exporting on, add these to `~/.claude/settings.json` `env` (see
`monitoring/README.md`):

```json
"CLAUDE_CODE_ENABLE_TELEMETRY": "1",
"OTEL_METRICS_EXPORTER": "otlp",
"OTEL_LOGS_EXPORTER": "otlp",
"OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
"OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317"
```

Machine-specific CLAUDE.md instructions (SSH hosts, cloud profiles) go in
`~/.claude/CLAUDE.local.md`, not the repo.

## 5. Verify — report results, don't just claim success

```sh
claude plugin list                                   # expect superpowers, oh-my-claudecode, ponytail, claude-mem
claude mcp list                                       # expect exa (context7 is the ctx7 CLI, not MCP)
npx -y ctx7 --version                                 # context7 CLI reachable
ls -l ~/.claude/CLAUDE.md ~/.claude/skills/jina-reader  # CLAUDE.md is a symlink into the repo
[ "${SKIP_JINA:-0}" = 1 ] || curl -fsS http://localhost:3333/https://example.com >/dev/null && echo "jina OK"
[ "${SKIP_OTEL:-0}" = 1 ] || curl -fsS http://localhost:13133 >/dev/null && echo "otel OK"
```

Report each check's result to the human. If a plugin is missing, re-run its
`claude plugin install` line.

## Two things to note

1. **Restart Claude Code** to load the new plugins and the linked CLAUDE.md.
2. **Run `omc setup` to finalize** (or `/oh-my-claudecode:omc-setup`).
