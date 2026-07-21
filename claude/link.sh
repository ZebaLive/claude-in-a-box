#!/usr/bin/env bash
# Merge this repo's CLAUDE-IN-A-BOX block into ~/.claude/CLAUDE.md and symlink
# the rest of the shared config, dotfiles-style. Idempotent.
#
# CLAUDE.md itself is NOT symlinked: OMC (`omc setup`) and rtk (`rtk init`)
# both write their own managed pieces into the same real file (OMC's
# "OMC:START" block, rtk's `@RTK.md` import). Symlinking the whole file would
# make each tool fight over ownership and force a strict run order. Instead
# this script upserts only the block between our own markers, leaving
# everything else in the file untouched — so OMC, rtk, and this repo can run
# in any order.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

link() {  # src rel-dest
  local src="$HERE/$1" dst="$DEST/$2"
  mkdir -p "$(dirname "$dst")"
  [ "$(readlink "$dst" 2>/dev/null)" = "$src" ] && { echo "ok    $2"; return; }
  [ -e "$dst" ] && [ ! -L "$dst" ] && { mv "$dst" "$dst.bak"; echo "backup $2 -> $2.bak"; }
  ln -sfn "$src" "$dst"
  echo "link  $2"
}

merge_claude_md() {
  local src="$HERE/CLAUDE.md" dst="$DEST/CLAUDE.md"
  local start='<!-- CLAUDE-IN-A-BOX:START -->' end='<!-- CLAUDE-IN-A-BOX:END -->'
  mkdir -p "$DEST"
  [ -e "$dst" ] && [ -L "$dst" ] && rm "$dst"  # older guide versions symlinked this file
  touch "$dst"
  if grep -qF "$start" "$dst"; then
    awk -v start="$start" -v end="$end" -v srcfile="$src" '
      $0 == start {
        while ((getline line < srcfile) > 0) print line   # srcfile already has its own start/end markers
        skipping=1; next
      }
      $0 == end { skipping=0; next }
      !skipping
    ' "$dst" > "$dst.tmp"
    mv "$dst.tmp" "$dst"
    echo "merge CLAUDE.md (updated our block)"
  else
    [ -s "$dst" ] && echo "" >> "$dst"
    cat "$src" >> "$dst"
    echo "merge CLAUDE.md (appended our block)"
  fi
}

merge_claude_md
link rules/context7.md  rules/context7.md

echo "Done. Machine-specific bits go in $DEST/CLAUDE.local.md (not managed here)."
