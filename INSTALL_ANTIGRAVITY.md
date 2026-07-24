# Antigravity Installation Guide - for an LLM agent

You are an AI coding agent setting up this machine with the owner's preferred
Antigravity stack. This guide is source-constrained: use only commands and
paths that are verified by upstream docs or local CLI help.

Repo: `ZebaLive/claude-in-a-box`

## 0. Detect the environment

```sh
uname -s
command -v agy || echo "MISSING: Antigravity CLI"
command -v git || echo "MISSING: git"
```

If `agy` is missing, install from the official Antigravity CLI README:

```sh
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

Then verify:

```sh
agy --help
```

## 1. Clone the repo

```sh
DIR="$HOME/.claude-in-a-box"
[ -d "$DIR/.git" ] || git clone https://github.com/ZebaLive/claude-in-a-box.git "$DIR"
cd "$DIR"
```

## 1.5 Install global Antigravity prompt file (GEMINI.md)

Copy this repo's shared Antigravity instructions into the global location
Antigravity reads:

```sh
mkdir -p ~/.gemini
cp antigravity/GEMINI.md ~/.gemini/GEMINI.md
```

This is the Antigravity equivalent of maintaining shared global instruction
context (similar role to `CLAUDE.md` / `AGENTS.md` in other stacks).

## 2. Optional one-command plugin migration

Antigravity CLI has a native import command:

```sh
agy plugin import claude
```

This imports only what Antigravity can discover from Claude-side extensions.
If nothing is found, install plugins explicitly in step 3.

## 3. Install Antigravity plugins that are source-verified

### superpowers

From `obra/superpowers` README:

```sh
agy plugin install https://github.com/obra/superpowers
```

### ponytail

From `DietrichGebert/ponytail` README:

```sh
agy plugin install https://github.com/DietrichGebert/ponytail
```

### claude-mem

From `thedotmack/claude-mem` Antigravity setup docs:

```sh
npx claude-mem install --ide antigravity
```

This installer configures hooks and context under the shared `~/.gemini`
config tree and writes MCP registration to both candidate files:

- `~/.gemini/antigravity/mcp_config.json`
- `~/.gemini/config/mcp_config.json`

## 4. Install context7 for Antigravity

From local `ctx7 setup --help`:

```sh
npx ctx7 setup --antigravity --cli -y
```

If you prefer MCP mode instead of CLI+skills mode:

```sh
npx ctx7 setup --antigravity --mcp -y
```

## 4.5 Configure Exa MCP for Antigravity

Load `.env` so `EXA_API_KEY` is available:

```sh
set -a && . ./.env && set +a
```

Write Exa into Antigravity's documented MCP server file
(`~/.gemini/config/mcp_servers.json`) using a merge (preserves existing
servers):

```sh
node <<'EOF'
const fs = require('fs');
const path = require('path');

const exaKey = process.env.EXA_API_KEY || '';
if (!exaKey) {
  console.error('EXA_API_KEY is empty. Set it in .env before this step.');
  process.exit(1);
}

const configDir = path.join(process.env.HOME, '.gemini', 'config');
const file = path.join(configDir, 'mcp_servers.json');
fs.mkdirSync(configDir, { recursive: true });

let doc = { servers: [] };
if (fs.existsSync(file)) {
  try {
    const parsed = JSON.parse(fs.readFileSync(file, 'utf8') || '{}');
    if (parsed && Array.isArray(parsed.servers)) doc = parsed;
  } catch (_) {
    // Keep default empty shape on parse failure.
  }
}

const next = {
  name: 'exa',
  command: 'npx',
  args: ['-y', 'exa-mcp-server'],
  env: { EXA_API_KEY: exaKey }
};

const i = doc.servers.findIndex(s => s && s.name === 'exa');
if (i >= 0) doc.servers[i] = next;
else doc.servers.push(next);

fs.writeFileSync(file, JSON.stringify(doc, null, 2) + '\n');
console.log(`Updated ${file}`);
EOF
```

Compatibility note: if your install still relies on `~/.gemini/config/mcp_config.json`,
keep it aligned manually or via your existing claude-mem flow.

## 5. Install rtk for Antigravity

Install `rtk` using your OS path (same as other stacks), then initialize the
Antigravity adapter.

macOS:

```sh
brew install rtk
```

Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

Initialize for Antigravity (verified in local `rtk init --help` and upstream
`rtk` README):

```sh
rtk init --agent antigravity
```

## 6. Shared local services (same as Claude/Codex stacks)

These scripts are already in this repo and are stack-agnostic:

```sh
./jina-ai/setup-jina.sh
./monitoring/setup-otel.sh
```

## 7. OMC/OMX exception (explicit)

`oh-my-claudecode` / `oh-my-codex` are not documented upstream as direct
Antigravity plugins installed via `agy plugin install`.

What is verified:
- OMC can orchestrate Antigravity workers (`agy`) from Claude-side workflows.
- Antigravity itself has plugin install/import commands.

Do not claim OMC/OMX are first-class Antigravity plugins unless their upstream
repos publish explicit `agy plugin install ...` instructions.

## 8. Global gitignore — nothing Antigravity-specific to add

The shared `.omc/` and `.omx/` entries are already covered by the Claude and Codex
install guides. No additional entries are needed for the Antigravity stack.

## 9. Verify and report

```sh
agy plugin help
agy plugin list
rtk init --show
npx -y ctx7 --version
npx claude-mem status
cat ~/.gemini/config/mcp_servers.json | grep -n 'exa\|exa-mcp-server'
curl -fsS http://localhost:3333/https://jina.ai >/dev/null && echo "jina OK"
curl -fsS http://localhost:13133 >/dev/null && echo "otel OK"
```

Also check shared config tree exists:

```sh
ls -1A ~/.gemini
ls -1A ~/.gemini/config
```

## Notes on source accuracy

- Antigravity plugin command surface is verified locally via `agy plugin help`.
- Antigravity install command is from official `google-antigravity/antigravity-cli` README.
- Superpowers and Ponytail Antigravity install commands are from their upstream READMEs.
- claude-mem Antigravity wiring and dual MCP config paths are from
  `docs/public/antigravity-cli/setup.mdx`.
- Exa MCP file path follows Antigravity docs that reference
  `~/.gemini/config/mcp_servers.json` for MCP servers.
- `ctx7 --antigravity` and `rtk init --agent antigravity` are verified from
  local CLI help and upstream RTK docs.
