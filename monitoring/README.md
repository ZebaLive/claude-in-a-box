# monitoring — Claude Code telemetry (OTel)

Local OpenTelemetry collector for Claude Code's own metrics/logs, all
endpoints bound to `127.0.0.1`.

```sh
./setup-otel.sh          # start collector + install login service
```

OS-aware: on macOS it runs in the shared `jina-ai` colima profile
(`docker --context colima-jina-ai`) and installs a LaunchAgent; on Linux it uses the native Docker daemon and installs a
systemd `--user` unit (`claude-code-otel.service`). See `jina-ai/README.md`
for the equivalent detail on that stack.

Exporting is enabled by default — `claude/shared-settings.json` already sets
these `env` vars, and `claude/merge-settings.sh` merges them into
`~/.claude/settings.json` (a machine-local value always wins if you want to
override one):

```json
"CLAUDE_CODE_ENABLE_TELEMETRY": "1",
"OTEL_METRICS_EXPORTER": "otlp",
"OTEL_LOGS_EXPORTER": "otlp",
"OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
"OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317"
```

## Endpoints

| Port | What |
|---|---|
| 4317 | OTLP gRPC — Claude Code exports here |
| 4318 | OTLP HTTP — handy for `curl` tests |
| 8889 | Prometheus scrape (`http://localhost:8889/metrics`) |
| 13133 | health check (`200` = pipelines running) |

## Where the data goes

- `data/events.jsonl` — logs. `data/metrics.jsonl` — metrics. (both gitignored)
- `docker logs -f claude-code-otel` — human-readable stdout.

This stack is not optional — `INSTALL.md` always has the agent run `setup-otel.sh`.
