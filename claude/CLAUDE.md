<!-- CLAUDE-IN-A-BOX:START -->
<!-- Managed by claude/link.sh; coexists with OMC's and rtk's own blocks below. -->

<stack>
Installed tooling and division of labor (rules self-inject via SessionStart hooks —
this block only orients, it does not restate them):
- **OMC** orchestrates: agents, skills, team pipeline.
- **ponytail** governs how much to build (lazy-senior discipline; default level `full`).
- **superpowers** enforces skill discipline (invoke a skill before acting).
- **claude-mem** is the memory system — persistent cross-session recall of past work. Reach for it whenever you want something from an earlier session (a decision, why something is the way it is, what was already tried) rather than assuming it is lost: `mem-search` skill, or the MCP `search` / `smart_search` / `get_observations` / `timeline` tools. Capture is automatic from the transcript at session end; there is no write API, so never hand-save a memory into it.
- **jina-reader** skill = local, private web fetch/screenshot (`localhost:3333`).
- **exa** MCP = web search. **context7** = `ctx7` CLI for live library docs.
- **rtk** rewrites Bash commands to compact equivalents via a PreToolUse hook (60-90% less token usage); see `@RTK.md` for its meta-commands (`rtk gain`, `rtk discover`, ...).
</stack>

<delegation_rules>
This CLAUDE.md authorizes the Agent tool. Spawn subagents without asking
me first when a trigger below fires.

Spawn for:

- Search that spans many files or naming conventions -> Explore.
- 2+ independent tasks with no shared state -> one agent each, parallel.
- Review or verification of work I just did -> code-reviewer or verifier,
  a separate lane, never self-approval.
- Implementation of an approved plan touching 3+ files -> executor.

Work directly for: single-file edits, one command, questions I can answer
from context I already hold, anything under ~3 tool calls.
</delegation_rules>

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

<change_descriptions>

- Make commit messages and pull request bodies as short as possible while preserving reviewer-relevant context and repository-required formats or templates.
- Use a concise imperative commit subject describing one logical change. Add a body only for non-obvious rationale, constraints, or consequences.
- In pull requests, state the problem, behavioral solution, verified testing, and material risks. Omit any section that is optional and has nothing useful to say.
- Do not narrate the implementation file by file, restate the diff, list routine commands, recount the work process, repeat information across sections, use promotional language, or include speculative and unverified claims.
- Before committing or opening a pull request, remove wording that does not help a reviewer understand the change, verify it, or assess its risk.
</change_descriptions>

<code_comments>

- Default to NO comments. This is enforced in code review — comments get flagged.
- Write a comment ONLY when it explains esoteric behaviour that is genuinely not obvious from reading the code: an external constraint, a non-obvious invariant, a subtle risk, or a workaround whose reason lives outside the file.
- Never comment syntax, control flow, assignments, standard library behavior, ordinary language behavior, section headers, or what clearly named code already says.
- Prefer clearer names and structure over explanatory comments. Do not use comments to compensate for confusing code.
- Keep required public API documentation, but do not turn docstrings into line-by-line implementation narration.
- Before finishing an edit, re-read every comment added or touched and delete any that merely paraphrase the code.
</code_comments>

<!-- Machine-specific bits go in ~/.claude/CLAUDE.local.md; uncomment to load: -->
<!-- @CLAUDE.local.md -->
<!-- CLAUDE-IN-A-BOX:END -->
