# Protocol: IA Sync Checker

Q3 closure audit: validate that the canonical doc tree is internally consistent after any documentation change. Audits three dimensions — routing-table synchronization, date freshness, and link integrity.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-sync-checker`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to run

- **Mandatory**: after any edit to [`docs/project.md`](../../docs/project.md) (Slices / stack), `docs/context/README.md`, `docs/_TAG-INDEX.md`, `docs/protocols/README.md`, or `.opencode/protocols/README.md`.
- **Recommended**: at the end of any session that modifies `docs/context/` or `docs/protocols/`.
- **Trigger**: the [documenter](../agents/subagents/documenter.md) or the [orchestrator](../agents/subagents/orchestrator.md) should invoke this protocol before closing a session that touched documentation.

## Routing-table synchronization audit

Four documents contain overlapping routing / decision-tree information. After any change to one of them, verify that the others reflect the same intent-to-route mapping.

| Document | Section to audit | Key content |
|---|---|---|
| `docs/project.md` | Slices table | Slice → repo / entry points / agents |
| `docs/context/README.md` | Index of context docs | Topic → primary doc → tags |
| `docs/_TAG-INDEX.md` | Tag-based lookup | Tag → file |
| `docs/protocols/README.md` | Project-protocol index | Topic → protocol |

**Verification steps:**

1. Extract all routing entries from each of the four tables.
2. For each unique intent (e.g. "read-only question", "fix a bug", "add a subagent"), verify that:
   - The target agent or subagent is consistent across all tables that mention it.
   - The target file / doc path is consistent (or at least not contradictory).
   - No table has an entry that is missing from the others without a valid reason.
3. Flag any discrepancy as a **SYNC ALERT**.

**SYNC ALERT format:**

```
SYNC ALERT — [Intent Name]
- Source: [document that has the correct / updated entry]
- Out of sync: [document(s) with stale or missing entry]
- Expected: [what the entry should say]
- Actual: [what the entry currently says]
```

## Date freshness (stale detection)

Scan all `.md` files in `docs/` and `.opencode/protocols/` that contain `last_updated` in their frontmatter.

**Rules:**

- **Stale threshold** — `last_updated` older than **30 days** from the current date.
- **Critical stale** — `last_updated` older than **90 days** — flag for review or removal.
- **Missing frontmatter** — files that should have `last_updated` but don't — flag for addition.

**Files exempt from stale check:**

- Per-session cache contents (session-specific, not hub docs).
- `task-memory.md` (updated only when milestones occur, not on every session).

**STALE ALERT format:**

```
STALE ALERT — [file path]
- last_updated: [date]
- Age: [X days]
- Severity: [Warning (>30d) / Critical (>90d)]
- Action: [Update date if still valid / Review content / Archive if obsolete]
```

## Link integrity check

For every relative markdown link `[text](path)` found in the routing documents, verify that the target file exists.

**Scope:**

- All `.md` files in `docs/context/`.
- All `.md` files in `docs/protocols/`.
- `docs/project.md`, `docs/context/README.md`, `docs/_TAG-INDEX.md`.
- All `.md` files in `.opencode/protocols/`.

**Verification steps:**

1. Parse all relative links (ignore `http://` and `https://` URLs).
2. Resolve each link relative to the file's directory.
3. Check if the target file exists.
4. Flag broken links as **LINK ALERT**.

**LINK ALERT format:**

```
LINK ALERT — [source file]
- Broken link: [text](path)
- Resolved path: [absolute or relative resolved path]
- Status: File not found
```

## Decision rules

- **Auto-fix allowed** — if a date is stale but the content is confirmed valid, update `last_updated` to the current date.
- **Never auto-fix routing** — if a routing-table discrepancy is found, present the SYNC ALERT to the user and ask which version is correct. Do not guess.
- **Fail-fast on broken links** — a broken link in a routing document is a critical issue — the hub's navigation is compromised.

## Output format

Return a **Sync Audit Report**:

```
## Sync Audit Report

### Routing Synchronization
- [ ] docs/project.md Slices ↔ docs/context/README.md
- [ ] docs/project.md Slices ↔ docs/_TAG-INDEX.md
- [ ] docs/project.md Slices ↔ docs/protocols/README.md
- [ ] docs/context/README.md ↔ docs/_TAG-INDEX.md
- [ ] docs/context/README.md ↔ docs/protocols/README.md
- [ ] docs/_TAG-INDEX.md ↔ docs/protocols/README.md

Status: [PASS / FAIL — list SYNC ALERTS if any]

### Date Freshness
- Total files scanned: [N]
- Stale files (>30d): [N]
- Critical stale (>90d): [N]
- Missing frontmatter: [N]

Status: [PASS / FAIL — list STALE ALERTS if any]

### Link Integrity
- Total links checked: [N]
- Broken links: [N]

Status: [PASS / FAIL — list LINK ALERTS if any]

### Summary
Overall: [PASS / FAIL]
Action Items: [list of required fixes]
```

## Constraints

- **PROHIBITED**: silently updating routing tables without user confirmation.
- **PROHIBITED**: skipping the link integrity check — broken links break the entire navigation system.
- **MANDATORY**: running this protocol after any edit to the routing documents.
- **MANDATORY**: including the full Sync Audit Report in the session output.

## Integration

This protocol is the closure counterpart of [ia-catalog-manager](./ia-catalog-manager.md) (which performs the CRUD operations). For prompts that ask to "audit", "inventory", or "validate" the doc tree without prior CRUD, prefer the [broad-investigation-template.md](./broad-investigation-template.md) scaffold (which is task-agnostic) and invoke the sync-checker as the specific audit. The sync-checker is also a good smoke-test before declaring a documentation milestone complete.
