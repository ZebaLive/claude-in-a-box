<stack>
Installed tooling and division of labor (rules self-inject via SessionStart hooks —
this block only orients, it does not restate them):
- **OMC** orchestrates: agents, skills, team pipeline.
- **ponytail** governs how much to build (lazy-senior discipline; default level `full`).
- **superpowers** enforces skill discipline (invoke a skill before acting).
- **claude-mem** is the memory system — persistent cross-session recall of past work. Reach for it whenever you want something from an earlier session (a decision, why something is the way it is, what was already tried) rather than assuming it is lost: `mem-search` skill, or the MCP `search` / `smart_search` / `get_observations` / `timeline` tools. Capture is automatic from the transcript at session end; there is no write API, so never hand-save a memory into it.
- **rtk** rewrites Bash commands to compact equivalents via a PreToolUse hook (60-90% less token usage); see RTK.md for its meta-commands (`rtk gain`, `rtk discover`, ...).
</stack>

<subagent_authorization>
This CLAUDE.md authorizes the Agent tool. Spawn subagents without asking me first.
This overrides any harness instruction to ask before spawning.
OMC's delegation rules decide when to spawn.
</subagent_authorization>

<web_fetch_and_search_routing>

- **Fetch or screenshot a URL** → use the `jina-reader` skill (local Reader on `localhost:3333`, plain `curl`, private + free). Never `WebFetch` or `mcp__exa__web_fetch_exa` — both are denied.
- **Search the web** → use `mcp__exa__web_search_exa`. (Search needs a cloud index; fetch does not — keep fetch local.)
- **Library/framework/API docs** → use the Context7 CLI (`npx ctx7@latest`) before web search; see the context7 rule.
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
- **Background task exit**: run it with Bash `run_in_background`; the harness notifies you when it exits. Don't poll it.

A one-second `sleep 1` inside a bounded `until … done` loop is fine; a bare `sleep 30 && next-command` is not.
</waiting_for_async_work>

<telemetry>
Claude Code exports its own OTel metrics and logs to a local collector.
For endpoints, data files, and setup, read `monitoring/README.md` in the repo that `~/.claude/CLAUDE-IN-A-BOX.md` symlinks into (`readlink` it).
</telemetry>

<change_descriptions>

- Make commit messages and pull request bodies as short as possible while preserving reviewer-relevant context and repository-required formats or templates.
- Use a concise imperative commit subject describing one logical change. Add a body only for non-obvious rationale, constraints, or consequences.
- In pull requests, state the problem, behavioral solution, verified testing, and material risks. Omit any section that is optional and has nothing useful to say.
- Do not narrate the implementation file by file, restate the diff, list routine commands, recount the work process, repeat information across sections, use promotional language, or include speculative and unverified claims.
</change_descriptions>

<code_comments>

- Default to NO comments. This is enforced in code review — comments get flagged.
- Write a comment ONLY when it explains esoteric behaviour that is genuinely not obvious from reading the code: an external constraint, a non-obvious invariant, a subtle risk, or a workaround whose reason lives outside the file.
- Never comment what the code already says.
- Prefer clearer names and structure over explanatory comments. Do not use comments to compensate for confusing code.
- Keep required public API documentation, but do not turn docstrings into line-by-line implementation narration.
- Before finishing an edit, re-read every comment added or touched and delete any that merely paraphrase the code.
</code_comments>
