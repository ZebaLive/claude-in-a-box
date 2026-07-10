#!/usr/bin/env bash
# Symlink the shared Claude config into ~/.claude, dotfiles-style.
# Idempotent. Backs up any existing real file to <path>.bak before linking.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

link() {  # src rel-dest
  local src="$HERE/$1" dst="$DEST/$2"
  mkdir -p "$(dirname "$dst")"
  # Already the right symlink? nothing to do.
  [ "$(readlink "$dst" 2>/dev/null)" = "$src" ] && { echo "ok    $2"; return; }
  # Real file in the way → back it up once.
  [ -e "$dst" ] && [ ! -L "$dst" ] && { mv "$dst" "$dst.bak"; echo "backup $2 -> $2.bak"; }
  ln -sfn "$src" "$dst"
  echo "link  $2"
}

link CLAUDE.md          CLAUDE.md
link rules/context7.md  rules/context7.md

echo "Done. Machine-specific bits go in $DEST/CLAUDE.local.md (not managed here)."
