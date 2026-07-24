#!/usr/bin/env bash
# Merge this repo's CODEX-IN-A-BOX block into ~/.codex/AGENTS.md, dotfiles-style.
# Idempotent — safe to re-run.
#
# AGENTS.md itself is NOT symlinked: OMX (`omx setup --scope user`) writes its
# own managed "OMX:AGENTS:START" block into the same real file. Wholesale-
# symlinking would make both tools fight over ownership. Instead this script
# upserts only the content between our own <!-- CODEX-IN-A-BOX:START/END -->
# markers, leaving OMX's pieces untouched — so omx setup and this script can
# run in any order.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CODEX_HOME:-$HOME/.codex}"

merge_agents_md() {
    local src="$HERE/AGENTS.md" dst="$DEST/AGENTS.md"
    local start='<!-- CODEX-IN-A-BOX:START -->' end='<!-- CODEX-IN-A-BOX:END -->'
    mkdir -p "$DEST"
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
        echo "merge AGENTS.md (updated our block)"
    else
        [ -s "$dst" ] && echo "" >> "$dst"
        cat "$src" >> "$dst"
        echo "merge AGENTS.md (appended our block)"
    fi
}

merge_agents_md

echo "Done. Machine-specific bits go in $DEST/AGENTS.local.md (import it from AGENTS.md if needed)."
