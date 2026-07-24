# Codex Installation Guide — for an LLM agent

You are an AI coding agent setting up this machine with the owner's preferred
Codex stack. This guide mirrors `INSTALL.md` (the Claude stack) but provisions
**Codex CLI + oh-my-codex** instead of Claude Code + oh-my-claudecode. The two
stacks share infrastructure (jina, OTel, claude-mem database) so many steps
below just verify an already-running service rather than install from scratch.

Same rules as the Claude guide: this is **agentic-install only**, each tool is
installed the way its maintainers document it, don't re-run a step that's
already satisfied, and stop and ask the human only where told to.

**Repo:** `ZebaLive/claude-in-a-box` (raw base:
`https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/`)

## 0. Detect the environment

```sh
uname -s
command -v codex  || echo "MISSING: Codex CLI — https://github.com/openai/codex"
command -v git    || echo "MISSING: git"
command -v node   || echo "MISSING: Node.js 20+ — https://nodejs.org"
codex --version
```

If Codex CLI or git is missing, stop and tell the human to install them first.
Node 20+ is required for OMX (oh-my-codex).

**Linux** — verify Codex is on `PATH` from its actual install location:
```sh
# Homebrew install puts it at /home/linuxbrew/.linuxbrew/bin/codex
# npm install puts it at $(npm root -g)/../bin/codex or ~/.local/bin/codex
which codex
```

## 1. Clone the repo

```sh
DIR="$HOME/.claude-in-a-box"
[ -d "$DIR/.git" ] || git clone https://github.com/ZebaLive/claude-in-a-box.git "$DIR"
cd "$DIR"
```

## 2. Collect secrets — ASK THE HUMAN

Same secrets as the Claude install. If `.env` already exists from the Claude
setup, load it and skip the copy step:

```sh
cp -n .env.example .env
```

Ask the human for (skip any already present in `.env`):
- `EXA_API_KEY` — from https://exa.ai
- `OPENAI_API_KEY` — from https://platform.openai.com — required for Codex
- `CONTEXT7_API_KEY` — from https://context7.com — **optional**

Write answers into `.env`, then load for this session:
```sh
set -a && . ./.env && set +a
```

## 3. Marketplaces + plugins

Codex has its own plugin system parallel to Claude's. Three plugins needed:
**oh-my-codex** (OMX — the workflow layer), **claude-mem** (shared memory),
and **ponytail** (lazy-senior build discipline). No Codex equivalent of
superpowers exists.

Idempotent — `marketplace add` no-ops if already present:

```sh
codex plugin marketplace add Yeachan-Heo/oh-my-codex
codex plugin marketplace add thedotmack/claude-mem
codex plugin marketplace add DietrichGebert/ponytail

codex plugin add oh-my-codex@Yeachan-Heo
codex plugin add claude-mem@thedotmack
codex plugin add ponytail@ponytail
```

Verify all three are present:
```sh
codex plugin list
```
Expect: `oh-my-codex`, `claude-mem`, and `ponytail` all listed and enabled.

## 4. MCP servers

Exa (web search) is the only MCP needed. If it's already in
`~/.codex/config.toml` from a previous setup, skip this:

```sh
grep -q 'mcp_servers.exa' ~/.codex/config.toml 2>/dev/null \
  && echo "exa already configured — skip" \
  || { [ -n "${EXA_API_KEY:-}" ] && codex mcp add exa --env "EXA_API_KEY=$EXA_API_KEY" -- npx -y exa-mcp-server; }
```

## 5. jina-reader skill + local Reader stack

The jina stack (Docker container + `/etc/hosts` entry) is shared with Claude.
If it's already running from the Claude setup, skip the Docker steps and just
copy the skill file:

```sh
mkdir -p ~/.codex/skills
cp -R skills/jina-reader ~/.codex/skills/jina-reader
```

If jina is **not** already running (fresh machine, no Claude setup yet), bring
it up first:
```sh
./jina-ai/setup-jina.sh   # OS-aware: colima+LaunchAgent (macOS) or native Docker+systemd --user (Linux)
```

Then verify it's reachable:
```sh
curl -fsS http://localhost:3333/https://example.com >/dev/null && echo "jina OK"
```

See `jina-ai/README.md` for full details.

## 6. OTel collector for telemetry

Same shared Docker stack as Claude. If already running, nothing to do:

```sh
curl -fsS http://localhost:13133 >/dev/null && echo "otel already running — skip" \
  || ./monitoring/setup-otel.sh
```

Codex telemetry is configured via a native `[otel]` section in `config.toml`
(not env vars like Claude). Step 9 below runs `merge-config.sh` which adds
this section automatically — nothing to do here besides confirm the collector
is up.

See `monitoring/README.md` for the full endpoint reference.

## 7. oh-my-codex — install CLI then run setup

The plugin from step 3 provides in-session skills (`$deep-interview`,
`$ralplan`, `$ultragoal`, etc.) but **does not** install OMX's hooks, native
agents, or write `~/.codex/AGENTS.md` — that requires `omx setup`:

```sh
command -v omx >/dev/null || npm install -g oh-my-codex

omx setup --scope user
```

`omx setup --scope user` writes `~/.codex/AGENTS.md` with its own managed
`<!-- OMX:AGENTS:START -->` block. That's fine to run in any order relative
to step 8 below — see step 8 for why nothing here fights over the file.

Verify:
```sh
omx --version
omx doctor
```

## 8. rtk — install it, then register for Codex

[rtk-ai/rtk](https://github.com/rtk-ai/rtk) supports Codex via `rtk init -g --codex`.
If rtk is already installed from the Claude setup, just run the second line:

```sh
command -v rtk >/dev/null || case "$(uname -s)" in
  Darwin) brew install rtk ;;
  Linux)  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
          export PATH="$HOME/.local/bin:$PATH" ;;
esac

rtk init -g --codex   # non-interactive; registers the PreToolUse hook for Codex
```

`rtk init -g --codex` registers the hook in Codex's config so Bash commands
are rewritten to compact equivalents before execution — same 60-90% token
savings as on the Claude side, but scoped to Codex sessions.

## 9. Shared config — merge CODEX-IN-A-BOX block + config.toml defaults

```sh
./codex/link.sh         # merges CODEX-IN-A-BOX block into ~/.codex/AGENTS.md
./codex/merge-config.sh # merges OTel + sandbox defaults into ~/.codex/config.toml
```

`link.sh` does **not** symlink `AGENTS.md` itself. OMX (`omx setup`) writes
its own `<!-- OMX:AGENTS:START -->` block into the same real file.
`link.sh` upserts only the content between its own
`<!-- CODEX-IN-A-BOX:START/END -->` markers, leaving OMX's pieces untouched —
so steps 7, 8, and 9 can run in **any order**, including re-runs.

`merge-config.sh` only adds sections that are not already present (setdefault
semantics — existing values in `config.toml` always win). It appends:

```toml
[otel]                                    # Codex native OTel — not env vars
environment = "dev"

[otel.exporter.otlp-grpc]
endpoint = "http://localhost:4317"

[otel.trace_exporter.otlp-grpc]
endpoint = "http://localhost:4317"

[otel.metrics_exporter.otlp-grpc]
endpoint = "http://localhost:4317"

sandbox_mode = "workspace-write"          # safe default; OS-level, not pattern matching
```

> **Note — no Read()/Bash() deny list for Codex.** Claude's
> `permissions.deny` glob patterns (`Read(~/.ssh/*)`, `Bash(rm -rf /*)`) have
> no direct equivalent in Codex. Codex uses OS-level sandboxing instead:
> `sandbox_mode = "workspace-write"` restricts writes to the workspace at the
> kernel/filesystem level, which is architecturally stronger for system
> protection than string-pattern matching on commands. Network domain
> allow/deny is available via `[permissions.profile.network]` if needed.

## 10. Shared memories — claude-mem bridges Claude ↔ Codex

claude-mem stores all observations in `~/.claude-mem/claude-mem.db`. Both the
Claude plugin (installed in `INSTALL.md`) and the Codex plugin (step 3 above)
read from and write to the **same** database — memory sharing is automatic, no
extra configuration needed.

Verify the worker is running (it auto-starts on first use):
```sh
curl -fsS http://localhost:$(node -e "
  const s = require('fs').existsSync;
  const p = \`\${process.env.HOME}/.claude-mem/settings.json\`;
  console.log(s(p) ? JSON.parse(require('fs').readFileSync(p)).WORKER_PORT || 3100 : 3100);
" 2>/dev/null || echo 3100)/health 2>/dev/null && echo "claude-mem worker OK" || echo "claude-mem worker not yet started (starts on first Codex session)"
```

During a Codex session, you can query shared memory with:
```
$mem-search "what we decided about auth last week"
```

## 11. Verify — report results, don't just claim success

```sh
codex plugin list                          # expect oh-my-codex, claude-mem, ponytail
codex mcp list                             # expect exa
omx --version && omx doctor                # OMX CLI installed + setup synced
rtk --version && rtk init --show           # rtk installed + Codex hook registered
grep -c "CODEX-IN-A-BOX:START\|OMX:AGENTS:START" ~/.codex/AGENTS.md   # expect 2
grep -q '^\[otel\]' ~/.codex/config.toml && echo "otel config OK"      # OTel TOML merged
grep -q '^sandbox_mode' ~/.codex/config.toml && echo "sandbox config OK"
ls -l ~/.codex/skills/jina-reader
curl -fsS http://localhost:3333/https://example.com >/dev/null && echo "jina OK"
curl -fsS http://localhost:13133 >/dev/null && echo "otel OK"
omx exec --skip-git-repo-check -C . "Reply with exactly OMX-EXEC-OK"   # proves Codex auth works

# service manager (informational — confirms stacks survive reboot)
if [ "$(uname -s)" = Darwin ]; then
  launchctl list | grep -E 'jina-ai|claude-code-otel'
else
  systemctl --user is-active claude-jina-ai.service claude-code-otel.service
fi
```

Report each check's result. If a plugin is missing, re-run its command from
step 3. If `omx doctor` reports issues, follow its output — it's designed to
self-diagnose.

## One thing to note

The Codex and Claude stacks share three services:

| Service | Where | Shared? |
|---------|-------|---------|
| jina-reader | Docker container on `:3333` | ✔ both use it |
| OTel collector | Docker container on `:4317`/`:13133` | ✔ both use it |
| claude-mem database | `~/.claude-mem/claude-mem.db` | ✔ same SQLite DB |
| rtk binary | `$(which rtk)` | ✔ one install, two registrations |

Only the agent runtimes (OMC vs OMX), their config dirs (`~/.claude` vs
`~/.codex`), and their plugin registrations are separate. Everything else is
intentionally shared.
