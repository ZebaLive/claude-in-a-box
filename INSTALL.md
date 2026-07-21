# Installation Guide — for an LLM agent

You are an AI coding agent (Claude Code, etc.) setting up this machine with the
owner's preferred Claude Code stack. This repo is **agentic-install only** —
there is no monolithic install script. Each tool below gets installed the way
its own maintainers document, using whatever package manager fits the machine
you're actually on. Use your judgment: check what's already present, adapt the
exact command to the OS/package manager in front of you, and don't re-run a
step that's already satisfied. Follow the steps in order; stop and ask the
human only where told to.

A few small helper scripts remain in this repo for the fiddly, easy-to-get-
wrong file operations (symlinking with backup, JSON settings merges, docker
compose + login-service wiring) — call those directly rather than
reimplementing their logic by hand. Everything else — package installs, `claude`
CLI invocations, `rtk init` — you run yourself, live, reasoning about the
result as you go.

**Repo:** `ZebaLive/claude-in-a-box` (raw base:
`https://raw.githubusercontent.com/ZebaLive/claude-in-a-box/main/`)

## 0. Detect the environment

```sh
uname -s                                 # Darwin (macOS) or Linux — both supported; anything else is not
command -v claude || echo "MISSING: Claude Code CLI — https://docs.claude.com/en/docs/claude-code"
command -v git    || echo "MISSING: git"
```

If Claude Code or git is missing, stop and tell the human to install it first
— don't work around it.

This stack is opinionated: jina, OTel, and rtk are **not optional**, and
docker (colima on macOS) is a hard requirement, same as Claude Code and git.

**macOS** needs colima too (the jina/otel stacks run in a colima VM):
```sh
command -v colima docker >/dev/null || brew install colima docker docker-compose
```

**Linux (Arch and similar)** needs the native Docker daemon + compose plugin,
and your user in the `docker` group:
```sh
command -v docker >/dev/null || sudo pacman -S docker docker-compose   # docker-compose provides the `docker compose` plugin
systemctl is-active --quiet docker || sudo systemctl enable --now docker
groups "$USER" | grep -q docker || { sudo usermod -aG docker "$USER"; echo "start a new login shell (or newgrp docker) before continuing"; }
```

Adapt package-manager commands (`pacman` above) to whatever the machine
actually uses if it isn't Arch.

## 1. Clone the repo

```sh
DIR="$HOME/.claude-in-a-box"
[ -d "$DIR/.git" ] || git clone https://github.com/ZebaLive/claude-in-a-box.git "$DIR"
cd "$DIR"
```

## 2. Collect secrets — ASK THE HUMAN

A couple of steps below need API keys. Do **not** invent them. Create `.env`
from the template, then ask the human for each value and fill it in:

```sh
cp -n .env.example .env
```

Ask the human for:
- `EXA_API_KEY` — from https://exa.ai
- `CONTEXT7_API_KEY` — from https://context7.com — **optional**, only raises `ctx7` CLI rate limits. Leave blank if they don't have one.

Write their answers into `.env`, then load it for the rest of this session:
```sh
set -a && . ./.env && set +a
```

A blank `EXA_API_KEY` means step 4's exa MCP server won't configure; a blank
`CONTEXT7_API_KEY` is fine (the `ctx7` CLI just runs at default rate limits).
Everything else below still installs regardless.

## 3. Marketplaces + plugins (bar is set to OMC)

Idempotent — `marketplace add` no-ops if already present, `plugin install` is
safe to re-run:

```sh
claude plugin marketplace add obra/superpowers-marketplace
claude plugin marketplace add Yeachan-Heo/oh-my-claudecode
claude plugin marketplace add DietrichGebert/ponytail
claude plugin marketplace add thedotmack/claude-mem

claude plugin install superpowers@superpowers-marketplace
claude plugin install claude-mem@thedotmack
claude plugin install oh-my-claudecode@omc
claude plugin install ponytail@ponytail
```

## 4. MCP servers — only what has no good CLI/skill path

Scope = user so it applies everywhere. context7 is the `ctx7` CLI (see
`claude/rules/context7.md`, linked in step 7); github is the `gh` CLI. Neither
needs an MCP server — only exa (web search) does, since there's no local
equivalent:

```sh
[ -n "${EXA_API_KEY:-}" ] && claude mcp add -s user exa -e "EXA_API_KEY=$EXA_API_KEY" -- npx -y exa-mcp-server
```

If `claude mcp add` errors because `exa` already exists, that's fine — it's
already configured.

## 5. oh-my-claudecode — sync via its own terminal CLI

The plugin from step 3 gives you the in-session `/autopilot`, `/team`, etc.
skills, but it does **not** install OMC's hooks/agents/skills/HUD/CLAUDE.md —
that only happens via OMC's own `omc setup`. Install the separate terminal
CLI (npm package, distinct from the plugin) and run its non-interactive sync:

```sh
command -v omc >/dev/null || npm i -g oh-my-claude-sisyphus@latest
omc setup --quiet   # non-interactive; syncs hooks, agents, skills, HUD, settings.json entries, CLAUDE.md
```

`omc setup` **refuses to run if `~/.claude/CLAUDE.md` is already a symlink**
(it writes a real file with its own `<!-- OMC:START -->` managed block). On a
fresh machine there's nothing to clear; on a re-run of this guide where step 7
already symlinked our curated CLAUDE.md in, clear that symlink first so OMC
can write through it again — step 7 puts our version back afterward regardless:

```sh
[ -L ~/.claude/CLAUDE.md ] && rm ~/.claude/CLAUDE.md
```

## 6. rtk — install it the way its own docs say to, then let it configure itself

[rtk-ai/rtk](https://github.com/rtk-ai/rtk) is a CLI proxy that rewrites Bash
commands (`git status`, `cargo test`, ...) to compact equivalents via a
PreToolUse hook — 60-90% less token usage per command. Install using whichever
method matches the OS from step 0, then let `rtk init` register itself —
don't hand-write the hook into `settings.json` yourself, `rtk init` already
knows the exact JSON it needs and keeps it in sync across versions:

```sh
command -v rtk >/dev/null || case "$(uname -s)" in
  Darwin) brew install rtk ;;
  Linux)  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
          export PATH="$HOME/.local/bin:$PATH" ;;
esac

rtk init -g --auto-patch   # non-interactive; registers the PreToolUse hook + appends an @RTK.md reference to CLAUDE.md
```

If a newer rtk version changes what `init` sets up, that's expected — you're
always getting the current version's own idea of correct configuration
rather than a copy we'd have to keep in sync by hand.

**Must run after step 5, not before**: `rtk init` writes straight through a
symlinked `CLAUDE.md` instead of refusing like OMC does — if step 7's symlink
were already in place, this would silently append into the *repo's tracked
file* through the link. Since step 5 already cleared any pre-existing symlink,
`rtk init` here always lands on a real file.

## 7. Shared config + settings (helper scripts — run these, don't hand-roll them; run LAST of the three)

```sh
./claude/link.sh            # symlinks CLAUDE.md + rules/ into ~/.claude, backs up any existing real file to .bak
./claude/merge-settings.sh  # merges claude/shared-settings.json into ~/.claude/settings.json (idempotent, machine values win)
```

Order matters: steps 5 and 6 above write a real, generated `~/.claude/CLAUDE.md`
(OMC's managed block, then rtk's `@RTK.md` line) and add their own entries
under `settings.json`'s `hooks` key. Run `link.sh` only now, once they're
done — it detects that generated file is a real (non-symlink) file and backs
it up to `.bak` before symlinking our curated `claude/CLAUDE.md` over it. That
curated file already covers OMC/rtk/ponytail/etc. by hand (see its `<stack>`
section and `@RTK.md` import), so nothing generated is lost by overwriting it
— the backup is disposable. `merge-settings.sh` then only fills in missing
`env`/`permissions` keys (`setdefault`-style), so it never touches the `hooks`
entries OMC and rtk already added.

`merge-settings.sh` is what turns on telemetry exporting by default
(`CLAUDE_CODE_ENABLE_TELEMETRY`, `OTEL_*` — see `monitoring/README.md`); there's
nothing further to configure for that unless the human wants to override a
value (a machine-local `settings.json` entry always wins over the merge).

## 8. jina-reader skill + local Reader stack

```sh
mkdir -p ~/.claude/skills
cp -R skills/jina-reader ~/.claude/skills/jina-reader

./jina-ai/setup-jina.sh   # OS-aware: colima+LaunchAgent (macOS) or native Docker+systemd --user (Linux)
```

See `jina-ai/README.md` for what the script does and why (`/etc/hosts` entry
for the presigned-URL host, the colima profile, the login service).

## 9. OTel collector for Claude Code's own telemetry

```sh
./monitoring/setup-otel.sh   # same OS-aware pattern as step 8
```

See `monitoring/README.md` for endpoints and where the data lands.

## 10. Verify — report results, don't just claim success

```sh
claude plugin list                                      # expect superpowers, oh-my-claudecode, ponytail, claude-mem
claude mcp list                                         # expect exa (context7 is the ctx7 CLI, not MCP)
npx -y ctx7 --version                                    # context7 CLI reachable
omc --version && ls ~/.claude/agents ~/.claude/hud       # omc CLI installed + setup synced agents/HUD
rtk --version && rtk init --show                         # rtk installed + hook registered in settings.json
ls -l ~/.claude/CLAUDE.md ~/.claude/skills/jina-reader   # CLAUDE.md is a symlink into the repo (not OMC's/rtk's generated file)
curl -fsS http://localhost:3333/https://example.com >/dev/null && echo "jina OK"
curl -fsS http://localhost:13133 >/dev/null && echo "otel OK"

# service manager (informational — confirms the stacks survive reboot/login)
if [ "$(uname -s)" = Darwin ]; then
  launchctl list | grep -E 'jina-ai|claude-code-otel'
else
  systemctl --user is-active claude-jina-ai.service claude-code-otel.service
fi
```

Report each check's result to the human. If a plugin or MCP server is
missing, re-run its command from step 3/4 rather than debugging blindly.

## One thing to note

**Restart Claude Code** to load the new plugins, the OMC hooks/agents/HUD, the
rtk hook, and the linked CLAUDE.md. (`omc setup` and `rtk init` already ran as
part of steps 5-6 above — there's no separate finalize step left to do by hand.)
