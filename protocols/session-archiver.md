# Protocol: Session Archiver

Distillation convention. Closes a session by reading every per-agent reasoning file and producing a single cross-agent digest. This is the second half of the write/distill cycle: the interruption bus produces the inputs, the session archiver consumes them.

## When to apply

- The human asks to "archive this session", "close the session", "distill", "summarize what we did".
- The session has reached a natural close (delivery is about to return the final response to the human and no further work is queued).
- The human is about to start a new session and explicitly says to "save", "persist", or "freeze" the current state.

Do **not** apply:

- Mid-session, while a subagent is still running. Wait for the subagent to return.
- For per-agent summaries — that is the subagent's job (`agents/{name}/summary.md`).
- For real-time memory — this is a one-shot distillation, not a streaming log.

## Inputs

| Artifact | Path (relative to session root) | Required |
|---|---|---|
| Per-agent reasoning | `agents/{name}/reasoning-full.md` | At least one |
| Per-agent summary | `agents/{name}/summary.md` | At least one |
| Traffic light | `traffic-light.md` | Optional but recommended |
| Interruption log | `interruption-log.md` | Optional but recommended |
| Session metadata | session directory name (contains date and keywords) | Yes — used in the digest header |

The session root is `~/.config/opencode/sessions/{human}/{project}/{DDMMYYYY-keywords}/` by default. The delivery agent or the orchestrator passes the absolute path when invoking this protocol.

## Output

A single file: `session-digest.md` at the session root. It contains:

1. **Header** — session name, date range, human, project, final semáforo state per agent.
2. **Decisions** — cross-agent decisions, deduplicated and grouped by topic. Each decision cites the agent that made it and the file path.
3. **Lessons learned** — cross-agent lessons, deduplicated. Each lesson cites the agent.
4. **Open questions** — questions left unanswered, from any agent's `reasoning-full.md` or `summary.md`.
5. **Links** — links to each `agents/{name}/summary.md` so the per-agent executive view is reachable.
6. **Interruptions summary** — count of human interventions, count of agent acknowledgments, and a short list of the most consequential hints.

## Process

1. **Discover** — list the contents of `agents/` to find every agent directory.
2. **Read** — for each `agents/{name}/`, read `reasoning-full.md` (if present) and `summary.md`. If a `reasoning-full.md` is already marked archived (`<!-- archived: {timestamp} -->` at the top), skip it and note in the digest that it was a re-archive of stale data.
3. **Extract** — pull out decisions, lessons, and open questions from each file. Tag every item with the agent name and a citation like `agents/coder/reasoning-full.md#L42`.
4. **Deduplicate** — merge decisions and lessons that appear in multiple agents. Prefer the most specific phrasing; keep all citations.
5. **Group** — organize decisions by topic (e.g., "Testing strategy", "Module boundaries", "Error handling") and lessons by severity (e.g., "Bugs to avoid", "Conventions to follow").
6. **Write** — produce `session-digest.md` at the session root.
7. **Mark archived** — prepend `<!-- archived: {ISO-8601 timestamp} -->` to each `agents/{name}/reasoning-full.md` that was consumed. Do NOT modify `summary.md` files — they remain the resume anchors for future sessions.
8. **Report** — return a short message: "Session archived. Digest: {session_root}/session-digest.md. Marked {N} reasoning files as archived. {M} summary files preserved."

## Output Template

```markdown
# Session Digest — {DDMMYYYY-keywords}

**Human**: {human_id}
**Project**: {project_id}
**Date range**: {started_at} → {closed_at}
**Agents involved**: {comma-separated list}

## Final Semáforo

| Agent | Final status | Summary |
|---|---|---|
| coder | success | Implemented 3 endpoints |
| tester | partial | Wrote 8 tests, 2 skipped |
| reviewer | success | Approved with 2 minor notes |

## Decisions

### {Topic group 1}
- **{Decision}** — cited from `agents/{agent}/reasoning-full.md` (also `agents/{other}/summary.md`).

### {Topic group 2}
- **{Decision}** — cited from `agents/{agent}/reasoning-full.md`.

## Lessons learned

### Bugs to avoid
- **{Lesson}** — cited from `agents/{agent}/reasoning-full.md`.

### Conventions to follow
- **{Lesson}** — cited from `agents/{agent}/reasoning-full.md`.

## Open questions

- {question 1} — from `agents/{agent}/reasoning-full.md`.
- {question 2} — from `agents/{other}/summary.md`.

## Interruptions summary

- Total human interventions: {N}
- Total agent acknowledgments: {N}
- Most consequential hints:
  - {ISO-8601 timestamp}: {one-line summary of the hint and how it was incorporated}

## Per-agent summaries

- coder — `agents/coder/summary.md`
- tester — `agents/tester/summary.md`
- reviewer — `agents/reviewer/summary.md`
- {etc.}
```

## Marking `reasoning-full.md` as Archived

To archive a reasoning file, prepend a single HTML comment line as the very first line of the file:

```markdown
<!-- archived: 2026-06-17T18:00:00Z -->
```

The original content below the comment is preserved unchanged. The next time the archiver runs on the same session, it sees the archive marker, skips the file, and notes in the new digest that the file was already archived.

Do NOT:

- Delete the file. It may be needed for compliance, debugging, or future re-distillation.
- Modify any line other than the prepended archive marker.
- Archive `summary.md` files. They are the resume anchors and must stay live.

## Interaction with the interruption bus

The interruption bus produces `reasoning-full.md` and `summary.md` files as a side effect of subagent work. The session archiver is the consumer of those files at session close. Together they form a complete cycle:

```
subagent work → reasoning-full.md + summary.md  (write phase)
session close → session-digest.md               (distill phase)
future session → reads summary.md               (resume phase)
```

## Rules

- Always run after all subagents have returned. Never archive while a subagent is still running.
- Never edit `reasoning-full.md` content — only prepend the archive marker.
- Never edit `summary.md` — it is the resume anchor.
- All output in ENGLISH.
- If no `agents/` directory exists or no reasoning files are present, write a minimal `session-digest.md` with an "Empty session" note rather than failing.
