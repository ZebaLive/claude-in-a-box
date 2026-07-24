<!-- CODEX-IN-A-BOX:START -->
<!-- Managed by codex/link.sh; coexists with OMX's own blocks below. -->

<stack>
Installed tooling and division of labor (rules self-inject via lifecycle hooks —
this block only orients, it does not restate them):
- **OMX** orchestrates: agents, skills, team pipeline.
- **superpowers** enforces skill discipline (invoke a skill before acting).
- **ponytail** governs how much to build (lazy-senior discipline; default level `full`).
- **claude-mem** provides persistent cross-session memory — shared with Claude
  via the same `~/.claude-mem/` database. Past Claude sessions are visible here,
  and vice versa.
- **jina-reader** skill = local, private web fetch/screenshot (`localhost:3333`).
- **exa** MCP = web search. **context7** = `npx ctx7 setup --codex` for live library docs.
</stack>

<shared_memory>
Memory is shared across Claude Code and Codex via `~/.claude-mem/`. Both agents
read from and write to the same SQLite + Chroma database. Use the `mem-search`
skill to query shared history. Memories written during a Claude session are
available in the next Codex session and vice versa.
</shared_memory>

<web_fetch_and_search_routing>
- **Fetch or screenshot a URL** → use the `jina-reader` skill (local Reader on
  `localhost:3333`, plain `curl`, private + free). Do not use raw web fetch
  tools — keep page content on-machine.
- **Search the web** → use the `exa` MCP tool. (Search needs a cloud index;
  fetch does not — keep fetch local.)
- Rationale: page content and screenshots stay on-machine; only search and the
  target site itself touch the network.
</web_fetch_and_search_routing>

<waiting_for_async_work>
Never `sleep N` to wait for something to become ready — poll a readiness signal
with a bounded timeout instead.

- **HTTP service**: `curl --retry 30 --retry-delay 1 --retry-connrefused -fsS http://host/health`
- **Port open**: `until nc -z host port; do sleep 1; done` inside `timeout 60 sh -c '...'`
- **Log line**: `timeout 60 tail -f file | grep -m1 'ready pattern'`

A one-second `sleep 1` inside a bounded `until … done` loop is fine; a bare
`sleep 30 && next-command` is not.
</waiting_for_async_work>
<!-- CODEX-IN-A-BOX:END -->
