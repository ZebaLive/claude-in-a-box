#!/usr/bin/env bash
# Bring up the Claude Code OTel collector in the shared jina-ai colima profile,
# and install a LaunchAgent to start it at login. macOS-only.
#
# Telemetry data (events.jsonl, metrics.jsonl) lands in ./data (gitignored).
# Enable exporting in Claude Code by setting these in ~/.claude/settings.json env:
#   CLAUDE_CODE_ENABLE_TELEMETRY=1, OTEL_METRICS_EXPORTER=otlp, OTEL_LOGS_EXPORTER=otlp,
#   OTEL_EXPORTER_OTLP_PROTOCOL=grpc, OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
have() { command -v "$1" >/dev/null 2>&1; }

have colima || { echo "colima not found: brew install colima docker docker-compose"; exit 1; }
mkdir -p "$HERE/data"

# Idempotent; co-exists with the jina LaunchAgent on the same profile.
colima start --profile jina-ai
docker --context colima-jina-ai compose -f "$HERE/docker-compose.yml" up -d

PLIST="$HOME/Library/LaunchAgents/com.claude-code-otel.plist"
sed "s#__HOME__/.claude/monitoring#$HERE#g; s#__HOME__#$HOME#g" \
  "$HERE/com.claude-code-otel.plist.template" > "$PLIST"
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo "Waiting for collector health on :13133 ..."
curl --retry 30 --retry-delay 1 --retry-connrefused -fsS \
  http://localhost:13133 >/dev/null && echo "Collector up. Metrics: http://localhost:8889/metrics"
