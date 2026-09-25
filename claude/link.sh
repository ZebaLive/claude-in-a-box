#!/usr/bin/env bash
# Link this repo's shared Claude instructions into ~/.claude and import them
# from CLAUDE.md alongside other tools' configuration. Idempotent.
#
# CLAUDE.md itself remains a real file because OMC (`omc setup`) and rtk
# (`rtk init`) write their own managed content there.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Backups land outside skills/ on purpose: a leftover jina-reader.bak beside
# jina-reader is a second SKILL.md claiming the same skill name.
link() {  # repo-rel-src rel-dest
  local src="$REPO/$1" dst="$DEST/$2"
  mkdir -p "$(dirname "$dst")"
  # Compare resolved targets, not link text: a profile dir chains its links
  # through ~/.claude, and relinking would drop that hop.
  [ "$(readlink -f "$dst" 2>/dev/null)" = "$(readlink -f "$src")" ] && { echo "ok    $2"; return; }
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local bak="$DEST/.backup/$2"
    mkdir -p "$(dirname "$bak")"; rm -rf "$bak"; mv "$dst" "$bak"
    echo "backup $2 -> .backup/$2"
  fi
  ln -sfn "$src" "$dst"
  echo "link  $2"
}

ensure_claude_import() {
  local dst="$DEST/CLAUDE.md" import='@CLAUDE-IN-A-BOX.md'
  local start='<!-- CLAUDE-IN-A-BOX:START -->' end='<!-- CLAUDE-IN-A-BOX:END -->'
  mkdir -p "$DEST"
  if [ -L "$dst" ]; then
    case "$(readlink "$dst")" in
      "$HERE"/*|"$REPO"/*) rm "$dst" ;;
      *) dst="$(readlink -f "$dst")"; echo "follow CLAUDE.md -> $dst" ;;
    esac
  fi
  touch "$dst"
  if awk -v start="$start" -v import="$import" -v end="$end" '
    $0 == start { starts++ }
    $0 == import { imports++ }
    $0 == end { ends++ }
    previous2 == start && previous1 == import && $0 == end { blocks++ }
    { previous2=previous1; previous1=$0 }
    END { exit !(starts == 1 && imports == 1 && ends == 1 && blocks == 1) }
  ' "$dst"; then
    echo "ok    CLAUDE.md import"
    return
  fi
  awk -v start="$start" -v import="$import" -v end="$end" '
      function emit() {
        if (!emitted) {
          print start
          print import
          print end
          emitted=1
        }
      }
      $0 == start { emit(); skipping=1; next }
      skipping && $0 == end { skipping=0; next }
      skipping { next }
      $0 == import { emit(); next }
      { print; last=$0 }
      END {
        if (!emitted) {
          if (NR > 0 && last != "") print ""
          emit()
        }
      }
  ' "$dst" > "$dst.tmp"
  mv "$dst.tmp" "$dst"
  echo "add   CLAUDE.md import"
}

link claude/CLAUDE.md           CLAUDE-IN-A-BOX.md
ensure_claude_import
link claude/rules/context7.md  rules/context7.md

# Symlinked, not copied: copies drift silently from the repo.
for d in "$REPO"/skills/*/; do
  name="$(basename "$d")"
  link "skills/$name" "skills/$name"
done

echo "Done. Machine-specific bits go in $DEST/CLAUDE.local.md (not managed here)."
