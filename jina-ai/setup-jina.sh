#!/usr/bin/env bash
# Bring up the local jina Reader (localhost:3333) in an isolated colima profile,
# and install a LaunchAgent to start it at login. macOS-only.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
have() { command -v "$1" >/dev/null 2>&1; }

have colima || { echo "colima not found: brew install colima docker docker-compose"; exit 1; }

# /etc/hosts entry: presigned screenshot URLs are signed for this host.
if ! grep -q 'minio.dev.jina.ai' /etc/hosts 2>/dev/null; then
  echo "Adding minio.dev.jina.ai to /etc/hosts (needs sudo)"
  echo "127.0.0.1 minio.dev.jina.ai" | sudo tee -a /etc/hosts >/dev/null
fi

colima start --profile jina-ai
docker --context colima-jina-ai compose -f "$HERE/docker-compose.yml" up -d

# LaunchAgent from template (__HOME__ -> $HOME).
PLIST="$HOME/Library/LaunchAgents/com.jina-ai.plist"
sed "s#__HOME__#$HOME#g; s#/Users/paulius/Development/jina-ai#$HERE#g" \
  "$HERE/com.jina-ai.plist.template" > "$PLIST"
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

# Wait for readiness instead of a blind sleep.
echo "Waiting for Reader on localhost:3333 ..."
curl --retry 30 --retry-delay 1 --retry-connrefused -fsS \
  http://localhost:3333/https://example.com >/dev/null && echo "Reader up."
