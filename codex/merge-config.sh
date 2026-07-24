#!/usr/bin/env bash
# Merge codex/shared-config.toml sections into ~/.codex/config.toml.
# Idempotent — skips any section already present (setdefault semantics).
# Does not modify keys already set; existing values always win.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CODEX_HOME:-$HOME/.codex}"
CONFIG="$DEST/config.toml"

mkdir -p "$DEST"
touch "$CONFIG"

# Check each managed section independently so partial merges are still safe.
merged=0

if ! grep -q '^\[otel\]' "$CONFIG"; then
    [ -s "$CONFIG" ] && echo "" >> "$CONFIG"
    cat "$HERE/shared-config.toml" >> "$CONFIG"
    echo "merge  config.toml (appended otel + sandbox sections)"
    merged=1
else
    echo "skip   config.toml ([otel] section already present — no changes)"
fi

# sandbox_mode is a top-level key (not a section header); check separately.
if [ "$merged" -eq 0 ] && ! grep -q '^sandbox_mode' "$CONFIG"; then
    echo "" >> "$CONFIG"
    echo "# sandbox — added by codex/merge-config.sh" >> "$CONFIG"
    echo 'sandbox_mode = "workspace-write"' >> "$CONFIG"
    echo "merge  config.toml (appended sandbox_mode)"
fi

echo "Done. To override a value, add it to $CONFIG above the managed block — earlier entries win in TOML merges."
