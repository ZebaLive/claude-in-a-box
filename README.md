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
install.sh              # entrypoint — marketplaces, plugins, MCP, skill
.env.example            # required API keys
skills/jina-reader/     # the jina-reader skill (SKILL.md)
jina-ai/                # local Reader stack (docker-compose + colima LaunchAgent)
  setup-jina.sh         # brings up the Reader, installs the LaunchAgent
```

## Not included

Machine-specific config kept out on purpose: AWS Bedrock env, the giant Bash
permission allowlist, token-optimizer, ebury/antigravity plugins, datadog MCP.
Those live in `~/.claude/settings.json` per-machine, not here. Add a
`settings.snippet.json` later if you want to template the safe parts.
