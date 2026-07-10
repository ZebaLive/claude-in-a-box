---
name: jina-reader
description: Fetch a URL as clean content (markdown/html/text, JS-rendered) or screenshot it, using the local self-hosted Jina Reader on localhost:3333. Use as the private, on-machine replacement for WebFetch — whenever you need to read/scrape a web page or PDF, or capture a screenshot of a URL.
---

# jina-reader (local, private)

Self-hosted Jina Reader at `http://localhost:3333`. Target URL is the path.
Private on-machine WebFetch replacement. No web search (cloud-only, absent).

Env override: `JINA_READER_URL` (default `http://localhost:3333`).

## Read a URL → clean content

`format` = `markdown` (default) | `html` | `text`.

```sh
curl -s -H "X-Respond-With: markdown" http://localhost:3333/https://example.com
```

Slow SPA? Add a render ceiling (seconds, not a fixed delay — fast pages still
return at once). Bump to 20-30 for heavy client-rendered sites:

```sh
curl -s -H "X-Respond-With: markdown" -H "X-Timeout: 25" http://localhost:3333/https://example.com
```

## Screenshot a URL → presigned PNG URL

Reader answers 302 → a time-limited MinIO URL. Capture the redirect, don't
follow it. `pageshot` = full scrollable page; `screenshot` = viewport only.

```sh
curl -s -o /dev/null -w '%{redirect_url}\n' -H "X-Respond-With: screenshot" http://localhost:3333/https://example.com
```

Requires `127.0.0.1 minio.dev.jina.ai` in /etc/hosts so the signed host
resolves (see ~/Development/jina-ai/README.md).

## If localhost:3333 is down

Start it: `cd ~/Development/jina-ai && docker --context colima-jina-ai compose up -d`
(LaunchAgent normally keeps it up at login).
