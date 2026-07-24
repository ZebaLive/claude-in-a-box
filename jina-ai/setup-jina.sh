#!/usr/bin/env bash
# Bring up the local jina Reader (localhost:3333) and keep it running across
# reboots/logins.
#   macOS: dedicated colima profile + LaunchAgent.
#   Linux (Arch, etc.): native Docker daemon + systemd --user unit.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
have() { command -v "$1" >/dev/null 2>&1; }
OS="$(uname -s)"

# /etc/hosts entry: presigned screenshot URLs are signed for this host.
if ! grep -q 'minio.dev.jina.ai' /etc/hosts 2>/dev/null; then
    echo "Adding minio.dev.jina.ai to /etc/hosts (needs sudo)"
    echo "127.0.0.1 minio.dev.jina.ai" | sudo tee -a /etc/hosts >/dev/null
fi

case "$OS" in
    Darwin)
        have colima || { echo "colima not found: brew install colima docker docker-compose"; exit 1; }
        
        colima start --profile jina-ai
        docker --context colima-jina-ai compose -f "$HERE/docker-compose.yml" up -d
        
        # LaunchAgent from template (__HOME__ -> $HOME).
        PLIST="$HOME/Library/LaunchAgents/com.jina-ai.plist"
        sed "s#__HOME__#$HOME#g; s#/Users/paulius/Development/jina-ai#$HERE#g" \
        "$HERE/com.jina-ai.plist.template" > "$PLIST"
        launchctl unload "$PLIST" 2>/dev/null || true
        launchctl load "$PLIST"
    ;;
    Linux)
        have docker || { echo "docker not found: sudo pacman -S docker docker-compose"; exit 1; }
        docker compose version >/dev/null 2>&1 || { echo "docker compose plugin not found: sudo pacman -S docker-compose"; exit 1; }
        
        systemctl is-active --quiet docker || { echo "Starting docker.service (needs sudo)"; sudo systemctl enable --now docker; }
        docker info >/dev/null 2>&1 || { echo "Can't reach the docker daemon. Add yourself to the docker group and start a new login shell: sudo usermod -aG docker \$USER"; exit 1; }
        
        docker compose -f "$HERE/docker-compose.yml" up -d
        
        # systemd --user unit from template (__HERE__ -> this dir), so it survives
        # reboots too (needs `loginctl enable-linger` to start without a login).
        UNIT_DIR="$HOME/.config/systemd/user"
        mkdir -p "$UNIT_DIR"
        sed "s#__HERE__#$HERE#g" "$HERE/claude-jina-ai.service.template" > "$UNIT_DIR/claude-jina-ai.service"
        systemctl --user daemon-reload
        systemctl --user enable --now claude-jina-ai.service
        loginctl enable-linger "$USER" 2>/dev/null || true
    ;;
    *)
        echo "Unsupported OS: $OS (jina-ai stack supports macOS and Linux)"; exit 1
    ;;
esac

# Wait for readiness instead of a blind sleep.
echo "Waiting for Reader on localhost:3333 ..."
curl --retry 30 --retry-delay 1 --retry-connrefused -fsS \
http://localhost:3333/https://jina.ai >/dev/null && echo "Reader up."
