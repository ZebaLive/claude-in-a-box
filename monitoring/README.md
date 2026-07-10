# monitoring — Claude Code telemetry (OTel)

Local OpenTelemetry collector for Claude Code's own metrics/logs. Runs in the
shared `jina-ai` colima profile, all endpoints bound to `127.0.0.1`.

```sh
./setup-otel.sh          # start collector + install login LaunchAgent
```

Then enable exporting in `~/.claude/settings.json` `env` (machine-local):

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

Skip during install with `SKIP_OTEL=1 ./install.sh`.
