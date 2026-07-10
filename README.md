# claude-in-a-box

Dotfiles-style, reproducible [Claude Code](https://docs.claude.com/en/docs/claude-code)
setup — my whole stack, packaged. Point an agent at `INSTALL.md` (or run one
script) and a fresh machine comes up fully configured: plugins, MCP servers,
skills, and local tooling.

**Bar is set to [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode).**
CLI + skills preferred over MCP; MCP is used only where there's no good CLI/skill path.

## Installation

### For humans

Paste this prompt to your LLM agent (Claude Code, etc.):

```
Set up this machine with my Claude Code stack by following the guide here:
https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/INSTALL.md
```

Or run it yourself — but letting the agent do it means the interactive parts
(API keys, verification) get handled:

```sh
git clone https://github.com/ZebaLive/claude-in-a-box.git ~/Development/claude-setups
cd ~/Development/claude-setups
cp .env.example .env && $EDITOR .env         # add your API keys
set -a && . ./.env && set +a && ./install.sh
# restart Claude Code
```

### For LLM agents

Fetch the guide and follow it:

```sh
curl -s https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/INSTALL.md
```

## What it installs

| Component | Source | How |
|---|---|---|
| superpowers | `obra/superpowers-marketplace` | plugin |
| oh-my-claudecode | `Yeachan-Heo/oh-my-claudecode` (`@omc`) | plugin |
| ponytail | `DietrichGebert/ponytail` | plugin — defaults to level `full` each session |
| claude-mem | `thedotmack/claude-mem` | plugin |
| context7 | `ctx7` (`npx ctx7`) | **CLI** + docs-lookup rule |
| exa search | `exa-mcp-server` | MCP (stdio, cloud index) |
| jina-reader | this repo | **skill** + local Reader on `localhost:3333` |

GitHub is handled by the `gh` CLI (no MCP server).

### Why these transports
- **Skills/CLI first** (ponytail principle): fewer moving parts, less token overhead than MCP.
- **jina = skill, not MCP.** Web fetch/screenshots stay on-machine via a self-hosted
  Reader. The skill is plain `curl` to `localhost:3333`. See `jina-ai/README.md`.
- **exa = MCP.** Web *search* needs a cloud index; no local equivalent.
- **context7 = CLI.** Live library docs via `npx ctx7 library` / `ctx7 docs`, driven by
  `rules/context7.md`. No MCP server, no token overhead when unused. `CONTEXT7_API_KEY` optional (rate limits only).
- **github = `gh` CLI.** No MCP server — `gh` covers PRs, issues, releases, and `gh api`.

## Secrets

Keys live in `.env` (gitignored) and are passed to the CLI at install time.
Nothing secret is committed. This repo is safe to make public. Rotate the keys
that were ever pasted into a local `~/.claude.json` before publishing.

## Layout

```
install.sh              # entrypoint — marketplaces, plugins, MCP, config, skill
.env.example            # required API keys
claude/                 # shared Claude config, symlinked into ~/.claude
  CLAUDE.md             # global instructions (OMC orchestration, routing, git)
  rules/context7.md     # Context7 docs-lookup rule
  link.sh               # symlinks the above into ~/.claude (backs up existing)
skills/jina-reader/     # the jina-reader skill (SKILL.md)
jina-ai/                # local Reader stack (docker-compose + colima LaunchAgent)
  setup-jina.sh         # brings up the Reader, installs the LaunchAgent
monitoring/             # OTel telemetry collector for Claude Code (optional)
  setup-otel.sh         # brings up the collector, installs the LaunchAgent
```

`SKIP_JINA=1` / `SKIP_OTEL=1` skip the respective local stacks.

## Shared config vs. machine-local

`claude/CLAUDE.md` and `claude/rules/` are **symlinked** into `~/.claude`, so
edits in this repo take effect live and are versioned. `link.sh` backs up any
existing real file to `.bak` before linking.

Machine-specific instructions (telemetry endpoints, SSH hosts, cloud profiles)
belong in `~/.claude/CLAUDE.local.md` — not managed here. `CLAUDE.md` has a
commented `@CLAUDE.local.md` import; uncomment it to load them.
