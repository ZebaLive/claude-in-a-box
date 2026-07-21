<!-- CLAUDE-IN-A-BOX:START -->
<!-- Managed by claude/link.sh; coexists with OMC's and rtk's own blocks below. -->

<stack>
Installed tooling and division of labor (rules self-inject via SessionStart hooks —
this block only orients, it does not restate them):
- **OMC** orchestrates: agents, skills, team pipeline.
- **ponytail** governs how much to build (lazy-senior discipline; default level `full`).
- **superpowers** enforces skill discipline (invoke a skill before acting).
- **claude-mem** provides persistent cross-session memory.
- **jina-reader** skill = local, private web fetch/screenshot (`localhost:3333`).
- **exa** MCP = web search. **context7** = `ctx7` CLI for live library docs.
- **rtk** rewrites Bash commands to compact equivalents via a PreToolUse hook (60-90% less token usage); see `@RTK.md` for its meta-commands (`rtk gain`, `rtk discover`, ...).
</stack>

<agent_model_selection>
Default subagents to `haiku`. Upgrade only when the task requires judgment:
- `haiku`: file reading, data gathering, counting, scanning, grep/search, formatting
- `sonnet`: analysis, code review, writing, cross-file reasoning, moderate synthesis
- `opus`: architecture decisions, novel debugging, ralplan, high-risk security review
</agent_model_selection>

<web_fetch_and_search_routing>
- **Fetch or screenshot a URL** → use the `jina-reader` skill (local Reader on `localhost:3333`, plain `curl`, private + free). Never `WebFetch` or `mcp__exa__web_fetch_exa` — both are denied.
- **Search the web** → use `mcp__exa__web_search_exa`. (Search needs a cloud index; fetch does not — keep fetch local.)
- **Library/framework/API docs** → use the Context7 CLI first (`npx ctx7 library` / `ctx7 docs`; see `rules/context7.md`), before web search.
- Rationale: page content and screenshots stay on-machine; only search and the target site itself touch the network.
</web_fetch_and_search_routing>

<waiting_for_async_work>
Never `sleep N` to wait for something to become ready — a blind sleep is either wasted time or a race. Poll a readiness signal with a bounded timeout.

- **HTTP service**: `curl --retry 30 --retry-delay 1 --retry-connrefused -fsS http://host/health` (or `wget --retry-connrefused --waitretry=1 --tries=30`).
- **Port open**: `until nc -z host port; do sleep 1; done` wrapped in `timeout 60 sh -c '...'`.
- **Kubernetes**: `kubectl wait --for=condition=ready pod/x --timeout=60s`, `kubectl rollout status deploy/x --timeout=120s`.
- **Docker**: `docker inspect -f '{{.State.Health.Status}}' <c>` loop, or `docker compose up --wait` (uses container healthchecks).
- **Process**: `while ! pgrep -x name >/dev/null; do sleep 1; done` inside a `timeout` cap.
- **Log line**: `timeout 60 tail -f file | grep -m1 'ready pattern'`.
- **File appears**: `until [ -f path ]; do sleep 1; done` inside `timeout`.
- **Background task exit**: keep the id from an async `run_in_terminal` and call `get_terminal_output` when notified — do not spin on `sleep`.
- **Claude Code's own telemetry**: OTel collector runs via docker compose — the shared `jina-ai` colima profile on macOS (host: `docker --context colima-jina-ai`), or the native Docker daemon on Linux (plain `docker`). Host loopback endpoints: OTLP gRPC `127.0.0.1:4317`, OTLP HTTP `127.0.0.1:4318`, Prometheus `http://127.0.0.1:8889/metrics`, health `http://127.0.0.1:13133`. Tail `<claude-setups>/monitoring/data/events.jsonl` for events. Setup: `monitoring/` in the claude-setups repo (auto-starts at login via LaunchAgent on macOS, systemd `--user` unit on Linux). Enable in Claude Code via the `CLAUDE_CODE_ENABLE_TELEMETRY`/`OTEL_*` env vars (machine-local `settings.json`).

A one-second `sleep 1` inside a bounded `until … done` loop is fine; a bare `sleep 30 && next-command` is not.
</waiting_for_async_work>

<!-- Machine-specific bits go in ~/.claude/CLAUDE.local.md; uncomment to load: -->
<!-- @CLAUDE.local.md -->
<!-- CLAUDE-IN-A-BOX:END -->
