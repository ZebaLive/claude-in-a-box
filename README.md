# claude-setups

Dotfiles-style, reproducible [Claude Code](https://docs.claude.com/en/docs/claude-code)
setup. One script installs my preferred plugins, MCP servers, and skills on a
fresh machine.

**Bar is set to [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode).**
CLI + skills preferred over MCP; MCP is used only where there's no good CLI/skill path.

## Quick start

```sh
git clone <this-repo> ~/Development/claude-setups && cd ~/Development/claude-setups
cp .env.example .env && $EDITOR .env         # add your API keys
set -a && . ./.env && set +a && ./install.sh
# restart Claude Code
```

## What it installs

| Component | Source | How |
|---|---|---|
| superpowers | `obra/superpowers-marketplace` | plugin |
| oh-my-claudecode | `Yeachan-Heo/oh-my-claudecode` (`@omc`) | plugin |
| ponytail | `DietrichGebert/ponytail` | plugin — defaults to level `full` each session |
| claude-mem | `thedotmack/claude-mem` | plugin |
| context7 | `@upstash/context7-mcp` | MCP (stdio, no CLI) |
| exa search | `exa-mcp-server` | MCP (stdio, cloud index) |
| jina-reader | this repo | **skill** + local Reader on `localhost:3333` |

GitHub is handled by the `gh` CLI (no MCP server).

### Why these transports
- **Skills/CLI first** (ponytail principle): fewer moving parts, less token overhead than MCP.
- **jina = skill, not MCP.** Web fetch/screenshots stay on-machine via a self-hosted
  Reader. The skill is plain `curl` to `localhost:3333`. See `jina-ai/README.md`.
- **exa = MCP.** Web *search* needs a cloud index; no local equivalent.
- **context7 = MCP.** Live library docs; stdio `npx`, no CLI.
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
```

## Shared config vs. machine-local

`claude/CLAUDE.md` and `claude/rules/` are **symlinked** into `~/.claude`, so
edits in this repo take effect live and are versioned. `link.sh` backs up any
existing real file to `.bak` before linking.

Machine-specific instructions (telemetry endpoints, SSH hosts, cloud profiles)
belong in `~/.claude/CLAUDE.local.md` — not managed here. `CLAUDE.md` has a
commented `@CLAUDE.local.md` import; uncomment it to load them.

## Not included

Kept out on purpose (machine-specific, not part of this stack): AWS Bedrock env,
the giant Bash permission allowlist, token-optimizer (a `~/.copilot` plugin),
ebury/antigravity plugins, datadog MCP. Those live in per-machine
`~/.claude/settings.json`. Plugin-owned hooks (ponytail, claude-mem, OMC HUD
statusline) register themselves on install — nothing to port.
