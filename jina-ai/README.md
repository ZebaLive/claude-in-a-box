# jina-ai — local Reader + MCP

Self-hosted [jina-ai/reader](https://github.com/jina-ai/reader) (`:oss`) as a
local WebFetch replacement, backed by a local MinIO bucket so screenshots
work too. MCP server exposes `read_url` (markdown/html/text, JS-rendered via
headless Chrome) and `capture_screenshot` (presigned MinIO PNG URL). Web
search and residential proxy are cloud-only and omitted.

## Screenshots & /etc/hosts (one-time, required for host-side access)

The reader returns screenshots as a **presigned S3 URL signed for the host
`minio.dev.jina.ai`**. That name resolves inside the docker network (compose
alias) but must also resolve on the host, or the signature host won't match:

```sh
echo "127.0.0.1 minio.dev.jina.ai" | sudo tee -a /etc/hosts
```

MinIO console: http://localhost:9001 (minio / minio123).

## Layout

| File | Purpose |
|---|---|
| `docker-compose.yml` | Runs the reader container on `localhost:3333` |
| `reader_mcp.py` | `uv` single-file MCP server (`read_url`, `capture_screenshot`) |
| `com.jina-ai.plist.template` | macOS LaunchAgent: starts the colima profile + container at login |
| `claude-jina-ai.service.template` | Linux systemd `--user` unit: starts the container at login |

## Runtime

Run `./setup-jina.sh` (also always run by `INSTALL.md` — this stack is not
optional). It's OS-aware:

- **macOS**: runs in a dedicated **colima profile** `jina-ai` (isolated from
  your other profiles), reached via docker context `colima-jina-ai`.
  ```sh
  colima start --profile jina-ai
  docker --context colima-jina-ai compose up -d
  ```
- **Linux (Arch, etc.)**: uses the native Docker daemon directly — no colima
  needed.
  ```sh
  docker compose up -d
  ```

Test either way:
```sh
curl http://localhost:3333/https://example.com
```

## Always-on

`setup-jina.sh` installs and enables the login service for you:

- **macOS**: a LaunchAgent (`~/Library/LaunchAgents/com.jina-ai.plist`) starts
  the `jina-ai` colima profile at login. Logs: `launchd.{out,err}.log`.
  ```sh
  launchctl unload ~/Library/LaunchAgents/com.jina-ai.plist   # stop permanently
  ```
- **Linux**: a systemd `--user` unit (`~/.config/systemd/user/claude-jina-ai.service`)
  starts the container at login (`loginctl enable-linger` lets it start even
  without an active session).
  ```sh
  systemctl --user status claude-jina-ai.service
  systemctl --user disable --now claude-jina-ai.service   # stop permanently
  ```

Either way the container itself is `restart: unless-stopped`, so it stays up
between the service manager runs.

## MCP tool

Registered with Claude Code (user scope) as `jina-reader`, exposing
`read_url(url, format=markdown|html|text)` and
`capture_screenshot(url, full_page=False)`:

```sh
claude mcp add -s user jina-reader -- uv run --script /Users/paulius/Development/jina-ai/reader_mcp.py
```

Env: `JINA_READER_URL` (default `http://localhost:3333`),
`JINA_READER_TIMEOUT` (default `60`).
