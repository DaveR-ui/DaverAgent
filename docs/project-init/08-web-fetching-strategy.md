# 08 — Web Fetching Strategy

> Experiential annotations on `webfetch` limitations and workarounds for reference material during project initialization.

---

## When to use webfetch

`webfetch` is a general-purpose URL fetcher. It converts HTTP to HTTPS automatically, supports `markdown` (default), `text`, and `html` formats, and accepts an optional timeout (max 120 seconds). Output is truncated at 2000 lines or 51200 bytes; the full output is saved to a file when truncated.

**Prefer dedicated tools over webfetch whenever possible:**

| Need | Tool |
|---|---|
| Angular docs | `angular-cli_search_documentation` |
| Angular code examples | `angular-cli_find_examples` |
| Angular/Opencode/VSCode docs lookup | `angular-expert`, `opencode-expert`, `vscode-expert` subagents |
| Raw GitHub file content | `webfetch` with `raw.githubusercontent.com` |
| GitHub directory listing | `webfetch` with `api.github.com` |

Only fall back to `webfetch` for raw GitHub content or GitHub API queries.

---

## GitHub raw file pattern

For raw file content (markdown, code, JSON):

```
https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}
```

Examples used during this project:

- design.md spec: `https://raw.githubusercontent.com/google-labs-code/design.md/main/docs/spec.md`
- design.md example: `https://raw.githubusercontent.com/google-labs-code/design.md/main/examples/{name}/DESIGN.md`

Known examples: `atmospheric-glass`, `paws-and-paths`, `totality-festival`.

## GitHub directory listing pattern

For listing a directory's contents (returns JSON array with `name`, `path`, `download_url`):

```
https://api.github.com/repos/{owner}/{repo}/contents/{path}
```

Example: `https://api.github.com/repos/google-labs-code/design.md/contents/examples`

---

## Truncation handling

When `webfetch` output exceeds 2000 lines or 51200 bytes, the tool reports:

> Full output saved to: {path}

**Do NOT read the full file yourself.** That blows the context budget. Instead, delegate to the `explore` subagent (Task tool) which can use Grep + Read with offset/limit to extract only the relevant sections.

---

## Gotchas

- **`raw.githubusercontent.com` is case-sensitive and branch-specific.** Use `main` (not `master`) for most modern repos. A wrong branch name returns a 404 with no useful body.
- **GitHub API rate limits: 60 requests/hour unauthenticated.** Don't spam it. Cache directory listings mentally and batch your queries.
- **`material.angular.dev/guide/theming` returns just "Angular Material UI Component Library"** via webfetch — the actual content is JS-rendered client-side. This is a known limitation; do not waste cycles retrying.
- **`v21.angular.dev/ecosystem/material/theming` redirects to the Angular homepage**, not the theming guide. The redirect is not followed to useful content.
- **Truncated output is saved to a file, not returned inline.** If you try to read that file directly, you consume the context you were trying to save. Always delegate to `explore`.
- **webfetch does not execute JavaScript.** Any SPA (Angular docs, Material docs, most modern framework sites) will return empty or minimal content. Use `angular-cli_search_documentation` instead.

---

## Quick Reference

| Item | Value |
|---|---|
| `webfetch` formats | `markdown` (default), `text`, `html` |
| `webfetch` timeout | max 120 seconds |
| Truncation threshold | 2000 lines or 51200 bytes |
| Raw GitHub pattern | `https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}` |
| GitHub API contents | `https://api.github.com/repos/{owner}/{repo}/contents/{path}` |
| Truncation handling | Delegate to `explore` subagent — do NOT read the file yourself |
| Angular docs | `angular-cli_search_documentation` (not webfetch) |
| Angular examples | `angular-cli_find_examples` (not webfetch) |
| Expert subagents | `angular-expert`, `opencode-expert`, `vscode-expert` (read-only) |

---

## Cross-references

- `09-material-theming-gotchas.md` — Material docs are JS-rendered; this file explains the workaround.
- `.opencode/docs/angular/` — Angular API reference (use instead of webfetch for Angular).
- `.opencode/docs/opencode/` — Opencode reference (use `opencode-expert` instead of webfetch).