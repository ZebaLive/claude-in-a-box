#!/usr/bin/env bash
# Bring up the Claude Code OTel collector and keep it running across
# reboots/logins.
#   macOS: shared jina-ai colima profile + LaunchAgent.
#   Linux (Arch, etc.): native Docker daemon + systemd --user unit.
#
# Telemetry data (events.jsonl, metrics.jsonl) lands in ./data (gitignored).
# Enable exporting in Claude Code by setting these in ~/.claude/settings.json env:
#   CLAUDE_CODE_ENABLE_TELEMETRY=1, OTEL_METRICS_EXPORTER=otlp, OTEL_LOGS_EXPORTER=otlp,
#   OTEL_EXPORTER_OTLP_PROTOCOL=grpc, OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
have() { command -v "$1" >/dev/null 2>&1; }
OS="$(uname -s)"
mkdir -p "$HERE/data"
chmod 777 "$HERE/data"   # otel-collector-contrib image runs as non-root UID 10001

case "$OS" in
Darwin)
  have colima || { echo "colima not found: brew install colima docker docker-compose"; exit 1; }

  # Idempotent; co-exists with the jina LaunchAgent on the same profile.
  colima start --profile jina-ai
  docker --context colima-jina-ai compose -f "$HERE/docker-compose.yml" up -d

  PLIST="$HOME/Library/LaunchAgents/com.claude-code-otel.plist"
  sed "s#__HOME__/.claude/monitoring#$HERE#g; s#__HOME__#$HOME#g" \
    "$HERE/com.claude-code-otel.plist.template" > "$PLIST"
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  ;;
Linux)
  have docker || { echo "docker not found: sudo pacman -S docker docker-compose"; exit 1; }
  docker compose version >/dev/null 2>&1 || { echo "docker compose plugin not found: sudo pacman -S docker-compose"; exit 1; }

  systemctl is-active --quiet docker || { echo "Starting docker.service (needs sudo)"; sudo systemctl enable --now docker; }
  docker info >/dev/null 2>&1 || { echo "Can't reach the docker daemon. Add yourself to the docker group and start a new login shell: sudo usermod -aG docker \$USER"; exit 1; }

  # Idempotent; co-exists with the jina systemd unit (separate compose project).
  docker compose -f "$HERE/docker-compose.yml" up -d

  UNIT_DIR="$HOME/.config/systemd/user"
  mkdir -p "$UNIT_DIR"
  sed "s#__HERE__#$HERE#g" "$HERE/claude-code-otel.service.template" > "$UNIT_DIR/claude-code-otel.service"
  systemctl --user daemon-reload
  systemctl --user enable --now claude-code-otel.service
  loginctl enable-linger "$USER" 2>/dev/null || true
  ;;
*)
  echo "Unsupported OS: $OS (otel stack supports macOS and Linux)"; exit 1
  ;;
esac

echo "Waiting for collector health on :13133 ..."
curl --retry 30 --retry-delay 1 --retry-connrefused -fsS \
  http://localhost:13133 >/dev/null && echo "Collector up. Metrics: http://localhost:8889/metrics"
