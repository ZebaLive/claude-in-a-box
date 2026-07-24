<!-- ANTIGRAVITY-IN-A-BOX:START -->
<!-- Managed by claude-in-a-box antigravity setup. -->

<stack>
Installed tooling and division of labor (rules self-inject via skills/plugins —
this block only orients, it does not restate them):
- **superpowers** enforces skill discipline (invoke a skill before acting).
- **ponytail** governs how much to build (lazy-senior discipline; default level `full`).
- **claude-mem** provides persistent cross-session memory.
- **jina-reader** skill = local, private web fetch/screenshot (`localhost:3333`).
- **context7** = `ctx7` CLI for live library docs.
- **rtk** rewrites commands into compact equivalents; initialized via `rtk init --agent antigravity`.
</stack>

<web_fetch_and_search_routing>
- **Fetch/screenshot a URL**: prefer the local `jina-reader` path (`localhost:3333`).
- **Library/framework/API docs**: use Context7 first (`npx ctx7 library` / `npx ctx7 docs`).
- **Web search**: use the `exa` MCP tool.
</web_fetch_and_search_routing>

<working_style>
- Prefer minimal changes that satisfy the requirement.
- Verify before claiming completion.
- Keep security constraints enabled; do not auto-approve risky commands.
</working_style>

<shared_services>
- Local Reader endpoint: `http://localhost:3333`
- OTel collector health: `http://localhost:13133`
- Shared memory backend: `~/.claude-mem/`
</shared_services>

<!-- ANTIGRAVITY-IN-A-BOX:END -->