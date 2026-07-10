#!/usr/bin/env bash
# Merge claude/shared-settings.json into ~/.claude/settings.json.
# Idempotent: unions permission allow/deny/ask lists, fills in missing env vars,
# and sets other top-level keys (e.g. attribution) only when absent. Never drops
# existing keys or entries — an existing machine value always wins.
# Backs up settings.json to settings.json.bak once before the first change.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$DEST/settings.json"
SRC="$HERE/shared-settings.json"

mkdir -p "$DEST"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

python3 - "$SETTINGS" "$SRC" <<'PY'
import json, sys, shutil, os
settings_path, src_path = sys.argv[1], sys.argv[2]
settings = json.load(open(settings_path))
src = json.load(open(src_path))

before = json.dumps(settings, sort_keys=True)

# Permissions: union each list, preserving existing entries and order.
perms = settings.setdefault("permissions", {})
for key in ("deny", "allow", "ask"):
    incoming = src.get("permissions", {}).get(key)
    if not incoming:
        continue
    existing = perms.setdefault(key, [])
    seen = set(existing)
    existing.extend(x for x in incoming if x not in seen)

# Env: fill in only missing keys — a machine-local value always wins.
env = settings.setdefault("env", {})
for k, v in src.get("env", {}).items():
    env.setdefault(k, v)

# Other top-level keys (e.g. attribution): set only if absent — machine wins.
for k, v in src.items():
    if k in ("permissions", "env"):
        continue
    settings.setdefault(k, v)

if json.dumps(settings, sort_keys=True) == before:
    print("ok    settings already merged")
else:
    if not os.path.exists(settings_path + ".bak"):
        shutil.copy2(settings_path, settings_path + ".bak")
        print("backup settings.json -> settings.json.bak")
    json.dump(settings, open(settings_path, "w"), indent=2)
    open(settings_path, "a").write("\n")
    print("merge  shared-settings -> settings.json")
PY
