---
name: jina-reader
description: Fetch a URL as clean content (markdown/html/text, JS-rendered) or screenshot it, using the local self-hosted Jina Reader on localhost:3333. Use as the private, on-machine replacement for WebFetch — whenever you need to read/scrape a web page, PDF, or github.com URL, or capture a screenshot of a URL.
---

# jina-reader (local, private)

Self-hosted Jina Reader at `http://localhost:3333`. Target URL is the path.
Private on-machine WebFetch replacement. No web search (cloud-only, absent).

Env override: `JINA_READER_URL` (default `http://localhost:3333`).

## github.com → try `gh` first

Target host is `github.com`? Reach for the GitHub CLI before the Reader. It is
authenticated (private repos work), and it returns the data instead of the page
around it.

The Reader silently truncates long threads. On `cli/cli#13840` (145 comments)
it rendered 23 and left `### 122 remaining items / Load more` in the output —
it cannot click the button. `gh issue view --comments` returned all 145. Short
threads survive but cost ~46x the tokens (one PR: 4 KB/61 lines vs 188 KB/3552)
in nav chrome and `Loading`/`error while loading` stubs from GitHub's lazy React.
Treat a `remaining items` or `Load more` marker in Reader output as data loss.

| github.com URL shape | command |
|---|---|
| `/O/R` | `gh repo view O/R` (prints the README) |
| `/O/R/blob/REF/PATH` | `gh api -H "Accept: application/vnd.github.raw" "repos/O/R/contents/PATH?ref=REF"` |
| `/O/R/issues/N` | `gh issue view N -R O/R --comments` |
| `/O/R/pull/N` | `gh pr view N -R O/R --comments`, plus `gh pr diff N -R O/R` |
| `/O/R/releases/tag/T` | `gh release view T -R O/R` (omit `T` for latest) |
| `gist.github.com/…/ID` | `gh gist view ID` |
| anything else | `gh api <rest/path>` — add `--jq` to filter, `--paginate` for lists |

`-R O/R` is required whenever the cwd is not that repo's checkout. `--json
<fields>` on `view` commands gives machine-readable output.

`--comments` prints *only* the comments — for the title and opening body run
the bare `view` as well. Both calls, not one, to reproduce a whole thread.

Fall back to the Reader when `gh auth status` fails or `gh` is absent, or when
you need a screenshot — `gh` has no equivalent. Hosts that merely look like
GitHub are not covered: `*.github.io` is an ordinary site for the Reader, and
`raw.githubusercontent.com` is already raw, so plain `curl` it (private repos:
use the `gh api` contents call above instead).

Quote any `gh api` endpoint carrying `?` — in zsh it is a glob and dies with
`no matches found`.

## Read a URL → clean content

`format` = `markdown` (default) | `html` | `text`.

```sh
curl -s -H "X-Respond-With: markdown" http://localhost:3333/https://jina.ai
```

Slow SPA? Add a render ceiling (seconds, not a fixed delay — fast pages still
return at once). Bump to 20-30 for heavy client-rendered sites:

```sh
curl -s -H "X-Respond-With: markdown" -H "X-Timeout: 25" http://localhost:3333/https://jina.ai
```

## Screenshot a URL → presigned PNG URL

Reader answers 302 → a time-limited MinIO URL. Capture the redirect, don't
follow it. `pageshot` = full scrollable page; `screenshot` = viewport only.

```sh
curl -s -o /dev/null -w '%{redirect_url}\n' -H "X-Respond-With: screenshot" http://localhost:3333/https://jina.ai
```

Requires `127.0.0.1 minio.dev.jina.ai` in /etc/hosts so the signed host
resolves (see `jina-ai/README.md` in the claude-in-a-box repo).

## If localhost:3333 is down

Start it: `cd ~/.claude-in-a-box/jina-ai && ./setup-jina.sh` (idempotent; picks
colima+LaunchAgent on macOS or native Docker+systemd `--user` on Linux). It
normally keeps itself up at login via that same login service.
