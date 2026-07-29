# Session Recovery Protocol

> How the agent system recovers from an interrupted or STUCK session in the
> `delivery` → `orchestrator` → subagent hierarchy. This protocol is the
> **fallback** for when an orchestrator session itself dies; intra-orchestrator
> child failures are already handled by the existing `STATUS: STUCK` path in
> `.opencode/agents/orchestrator.md`.

## Purpose

Sessions in opencode are persistent server-side objects. When a session is
interrupted mid-flight (HTTP timeout, credit exhaustion, manual abort, unexpected
termination), the work it was doing does not disappear — it is still addressable
via the opencode session API. This protocol defines how to inspect a failed
session, clean up its still-running children, and produce a handoff snapshot
that a fresh orchestrator instance can consume through the
`## Resume instructions (if restart)` block of `.opencode/agents/orchestrator.md`
(L194-201). Without this protocol, an interrupted orchestrator forces the human
to reconstruct context by hand; with it, recovery is a mechanical API walk.

## When to apply

Apply this protocol when you observe any of the following:

- `STATUS: STUCK` returned by an orchestrator.
- A `Subagent.Interrupted` event on the EventV2 bus (see
  `.opencode/agents/orchestrator.md` — Subagent outcomes block and interruption
  notes).
- `POST /session/:id/abort` triggered by `delivery` (see
  `.opencode/agents/orchestrator.md` — Strategic Pauses).
- A human pastes a session URI like
  `oc://renderer/server/c2lkZWNhcg/session/ses_xxx...`.
- HTTP timeout, credit exhaustion, or unexpected termination mid-flight.

## URI parser

Session URIs have the shape:

```
oc://renderer/server/<base64>/session/<id>
```

- The `<base64>` segment is a **per-server name**. Example: `c2lkZWNhcg`
  base64-decodes to `"sidecar"`. It is safe to log.
- The `<id>` segment after `/session/` is the real **API id** used in every
  endpoint below (e.g. `ses_050bab171ffevVZj1KPclKHp3R`).

How to parse (pseudo-steps, not code):

1. Split the URI on `/session/`. The tail is the API id.
2. Take the head, split on `/server/`, base64-decode the tail to get the
   server name (informational only).
3. Use the API id from step 1 in all `GET`/`POST /session/:id/...` calls.

## Server discovery & auth

- Base URL: `OPENCODE_SERVER_URL` env var; fallback `http://127.0.0.1:4096`.
- Auth: HTTP Basic. Username `opencode` (override via
  `OPENCODE_SERVER_USERNAME`), password from `OPENCODE_SERVER_PASSWORD`.
- **The password comes from the environment only — never from disk, never from
  command-line arguments, never into logs.**
- Advanced (not covered by the helper script): mDNS discovery via `--mdns` /
  `--mdns-domain opencode.local`.

## Recovery flow per depth level

### Mode 1 — `delivery` interrupted

Nothing to recover. `delivery` holds no durable task state; the new delivery
session reloads `docs/` on its next prompt and the human re-states the request.
One sentence of context from the human is sufficient.

### Mode 2 — `orchestrator` interrupted (PRIMARY case)

Walk the opencode session API in this order:

1. `GET /global/health` — pre-flight check that the server is reachable.
2. `GET /session/status` — map of session id → state; find whether the failed
   session is `running`, `idle`, or something else.
3. `GET /session/:id` — metadata of the failed orchestrator (title, parentID,
   timestamps).
4. `GET /session/:id/children` — list coder/tester/etc. children as
   `ChildInfo { status, summary, agentType, durationMs }`.
5. For each child still in `running`: `POST /session/:id/abort` (cleanup
   before resume).
6. If the orchestrator session itself is still `running`:
   `POST /session/:id/abort`.
7. `GET /session/:id/message?limit=20` — last 20 messages for context.
8. `GET /session/:id/todo` — pending todo list.
9. `GET /session/:id/diff` — files changed so far (optionally
   `?messageID=<msgID>` for a per-message diff).
10. Resume: `POST /session` with
    `{ "parentID": "<failed_id>", "title": "Resume of <original-title>" }`.
    The new session inherits the lineage.
11. Alternative "clean" resume: `POST /session/:id/fork` with
    `{ "messageID": "<checkpoint>" }` — fork at a specific known-good message,
    discarding any half-applied diff after that point.

### Mode 3 — subagent child interrupted inside a LIVE orchestrator

Already handled by `STATUS: STUCK` in `.opencode/agents/orchestrator.md`. This
protocol is the fallback for when the orchestrator itself died; intra-orchestrator
child failures are managed by the existing `STATUS: STUCK` path.

## Output shape

The "recovered snapshot" produced by the Mode 2 walk MUST map 1:1 to the four
fields of the `## Resume instructions (if restart)` block in
`.opencode/agents/orchestrator.md` (L194-201):

- **Original task** ← recovered from `GET /session/:id` title or the first
  user message.
- **Acceptance criteria still open** ← recovered from `GET /session/:id/todo`.
- **Latest state** ← one-paragraph summary synthesized from the last messages
  (`GET /session/:id/message?limit=20`).
- **Next concrete step** ← the first unchecked todo item, or inferred from the
  last assistant message.

## Helper script

`.opencode/scripts/session-recover.ps1` (PowerShell 5.1+) wraps every endpoint
above as a sub-command (`health`, `list`, `status`, `inspect`, `children`,
`abort`, `messages`, `todo`, `diff`, `resume`). The script is **dumb**: it does
HTTP and prints JSON to stdout. All decisions about what to do with the data
live in this protocol. It is invoked manually by the user or by a future
orchestrator on STUCK recovery — never by `delivery` or `interpreter`.

## Cross-references

- `.opencode/agents/orchestrator.md` — Strategic Pauses section: existing
  `POST /session/:id/abort` mention.
- `.opencode/agents/orchestrator.md` L194-201 — `## Resume instructions (if
  restart)` block: consumer of this protocol's output.
- `.opencode/agents/delivery.md` — Session Preflight / Interrupted Session
  Recovery note.
- <https://opencode.ai/docs/server/#sessions> (English) /
  <https://opencode.ai/docs/es/server/#sesiones> (Spanish).

## Caveats / non-goals

- **PowerShell-only helper.** A bash twin of `session-recover.ps1` is out of
  scope for now (the user's primary environment is Windows PowerShell); flagged
  as future work.
- **Single-server assumption.** Multi-server orchestration is out of scope; the
  flow assumes one `sidecar` server.
- **No automatic invocation.** The script is run manually by the user or by a
  future orchestrator recovering from STUCK. It is NOT invoked by `delivery`
  or `interpreter`.
- **No auto-deletion of failed sessions.** Failed sessions are left in place.
  The user may delete them via `DELETE /session/:id` if desired (endpoint noted
  here for reference; intentionally not scripted).
