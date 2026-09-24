# claude-in-a-box

Dotfiles-style, reproducible [Claude Code](https://docs.claude.com/en/docs/claude-code)
setup — my whole stack, packaged. **Agentic-install only**: there is no
monolithic install script. Point an agent at `INSTALL.md` and it installs each
tool the way its own maintainers document (brew/curl/cargo, `claude plugin`,
`rtk init`, ...), adapting to whatever OS/package manager it finds, and calls
out to a few small helper scripts only for the fiddly file operations
(symlink+backup, JSON settings merge, docker compose wiring).

**Bar is set to [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode).**
CLI + skills preferred over MCP; MCP is used only where there's no good CLI/skill path.

## Installation

### Claude stack

#### For humans

Paste this prompt to your LLM agent (Claude Code, etc.):

```
Set up this machine with my Claude Code stack by following the guide here:
https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/INSTALL.md
```

You can also follow `INSTALL.md` yourself — it's plain shell commands with
reasoning attached, not a script you must run as a black box — but letting an
agent drive means the interactive parts (API keys, verification, adapting
commands to your actual OS) get handled for you.

#### For LLM agents

Fetch the guide and follow it:

```sh
curl -s https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/INSTALL.md
```

### Codex stack

#### For humans

Install the Claude stack first (shared services — jina, OTel, claude-mem — run
once for both), then:

```
Set up this machine with my Codex stack by following the guide here:
https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/INSTALL_CODEX.md
```

#### For LLM agents

```sh
curl -s https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/INSTALL_CODEX.md
```

### Antigravity stack

#### For humans

Install the Claude stack first (shared services - jina, OTel, claude-mem), then:

```
Set up this machine with my Antigravity stack by following the guide here:
https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/INSTALL_ANTIGRAVITY.md
```

#### For LLM agents

```sh
curl -s https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/INSTALL_ANTIGRAVITY.md
```

## What it installs

### Claude stack

| Component | Source | How |
|---|---|---|
| superpowers | `obra/superpowers-marketplace` | plugin |
| oh-my-claudecode | `Yeachan-Heo/oh-my-claudecode` (`@omc`) | plugin (in-session skills) + npm `omc` **CLI** (`omc setup` syncs hooks/agents/HUD) |
| ponytail | `DietrichGebert/ponytail` | plugin — defaults to level `full` each session |
| claude-mem | `thedotmack/claude-mem` | plugin |
| context7 | `ctx7` (`npx ctx7`) | **CLI** + docs-lookup rule |
| exa search | `exa-mcp-server` | MCP (stdio, cloud index) |
| jina-reader | this repo | **skill** + local Reader on `localhost:3333` |
| rtk | [`rtk-ai/rtk`](https://github.com/rtk-ai/rtk) | **CLI** + PreToolUse hook (rewrites Bash commands) |

GitHub is handled by the `gh` CLI (no MCP server).

### Codex stack

Shares jina, OTel, and the claude-mem database with the Claude stack.
All four Claude plugins now have Codex equivalents.

| Component | Source | How |
|---|---|---|
| oh-my-codex (OMX) | `Yeachan-Heo/oh-my-codex` | plugin + npm `omx` **CLI** (`omx setup --scope user` syncs hooks/agents/AGENTS.md) |
| superpowers | `obra/superpowers` (Codex plugin at `superpowers-dev`) | plugin |
| ponytail | `DietrichGebert/ponytail` | plugin |
| claude-mem | `thedotmack/claude-mem` | plugin — **shared db** with Claude (`~/.claude-mem/`) |
| context7 | `ctx7` (`npx ctx7 setup --codex`) | **CLI** — same `ctx7` binary as Claude, Codex-specific setup |
| exa search | `exa-mcp-server` | MCP (stdio, same server as Claude) |
| jina-reader | this repo | **skill** + shared local Reader on `localhost:3333` |
| rtk | [`rtk-ai/rtk`](https://github.com/rtk-ai/rtk) | `rtk init -g --codex` registers Codex hook |

### Why these transports
- **Skills/CLI first** (ponytail principle): fewer moving parts, less token overhead than MCP.
- **jina = skill, not MCP.** Web fetch/screenshots stay on-machine via a self-hosted
  Reader. The skill is plain `curl` to `localhost:3333`. See `jina-ai/README.md`.
- **exa = MCP.** Web *search* needs a cloud index; no local equivalent.
- **context7 = CLI.** Live library docs via `npx ctx7 library` / `ctx7 docs`, driven by
  `rules/context7.md`. No MCP server, no token overhead when unused. `CONTEXT7_API_KEY` optional (rate limits only).
- **github = `gh` CLI.** No MCP server — `gh` covers PRs, issues, releases, and `gh api`.
- **rtk = CLI + hook, not MCP.** A `PreToolUse` hook transparently rewrites Bash
  commands (`git status`, `cargo test`, ...) to compact `rtk` equivalents before
  execution — 60-90% less token usage per command, zero prompting overhead.

## Secrets

Keys live in `.env` (gitignored) and are read by the agent at install time
(`set -a && . ./.env && set +a`). Nothing secret is committed. This repo is
safe to make public. Rotate the keys that were ever pasted into a local
`~/.claude.json` before publishing.

## Layout

```
INSTALL.md              # Claude stack entrypoint — step-by-step agent instructions
INSTALL_CODEX.md        # Codex stack entrypoint — mirrors INSTALL.md for Codex CLI
INSTALL_ANTIGRAVITY.md  # Antigravity stack entrypoint - source-verified plugin/CLI wiring
.env.example            # required API keys
claude/                 # shared Claude config, symlinked into ~/.claude
  CLAUDE.md             # global instructions (OMC orchestration, routing, git)
  rules/context7.md     # Context7 docs-lookup rule
  link.sh               # helper: links CLAUDE-IN-A-BOX.md and imports it from ~/.claude/CLAUDE.md
  merge-settings.sh     # helper: merges shared-settings.json into ~/.claude/settings.json
codex/                  # shared Codex config, merged into ~/.codex
  AGENTS.md             # global instructions (OMX orchestration, shared memory)
  link.sh               # helper: upserts CODEX-IN-A-BOX block into ~/.codex/AGENTS.md
  merge-config.sh       # helper: merges OTel + sandbox defaults into ~/.codex/config.toml
  shared-config.toml    # base config (OTel grpc exporters, sandbox_mode)
antigravity/            # shared Antigravity prompt/config snippets
  GEMINI.md             # global instructions copied to ~/.gemini/GEMINI.md
skills/jina-reader/     # the jina-reader skill (SKILL.md)
jina-ai/                # local Reader stack (docker-compose; colima+LaunchAgent on
                         #   macOS, native Docker+systemd --user on Linux)
  setup-jina.sh         # helper: brings up the Reader, installs the login service
monitoring/             # OTel telemetry collector for Claude Code
  setup-otel.sh         # helper: brings up the collector, installs the login service
```

`rtk` itself lives outside this repo ([`rtk-ai/rtk`](https://github.com/rtk-ai/rtk)).
`INSTALL.md` has the agent install the binary (brew on macOS, vendor script on
Linux) and run `rtk init -g --auto-patch` itself, rather than us vendoring a
copy of the hook JSON it writes into `~/.claude/settings.json` — that way it
always matches whatever the installed rtk version actually expects.

This stack is opinionated: jina, OTel, and rtk always install — there are no
skip flags. Docker (colima on macOS) is a hard requirement, same as the
Claude Code CLI itself.

## Shared config vs. machine-local

`claude/CLAUDE.md` and `claude/rules/` are **symlinked** into `~/.claude`, so
edits in this repo take effect live and are versioned. `link.sh` backs up any
existing real file to `.bak` before linking.

Machine-specific instructions (telemetry endpoints, SSH hosts, cloud profiles)
belong in `~/.claude/CLAUDE.local.md` — not managed here. `CLAUDE.md` has a
commented `@CLAUDE.local.md` import; uncomment it to load them.

**Ordering gotcha, handled in `INSTALL.md`:** both `omc setup` and `rtk init`
want to write `~/.claude/CLAUDE.md` themselves (OMC refuses outright if it's
already our symlink; rtk isn't as careful and will write straight through the
symlink into the repo's tracked file). `INSTALL.md` runs `omc setup` and
`rtk init` *before* `link.sh`, so they land on a real file, then `link.sh`
backs that generated file up and puts our symlink back on top. Our `CLAUDE.md`
carries a permanent `@RTK.md` import so the rtk-generated meta-command
reference (`rtk gain`, `rtk discover`, ...) still loads even though the line
rtk itself appends gets overwritten.
