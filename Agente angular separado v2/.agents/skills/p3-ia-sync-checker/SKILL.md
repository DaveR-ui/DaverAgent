---
name: sync-checker
description: Verification skill for the Q3 closure stage. Audits routing table consistency across documentation, detects stale dates, and validates link integrity across the Agent Knowledge Hub.
last_updated: 2026-05-09
status: active
---

# 🔗 Skill: Sync Checker (Q3 Closure — Documentation Audit)

## Goal
Ensure the Agent Knowledge Hub remains internally consistent after any documentation change. This skill runs in the **Q3 (Cierre)** stage and validates three dimensions: routing table synchronization, date freshness, and link integrity.

## When to Run

- **Mandatory**: After any edit to `CHEATSHEET.md`, `orchestrate.md`, `AGENTS.md`, or `_TAG-INDEX.md`.
- **Recommended**: At the end of any session that modifies `.agents/context/` or `.agents/skills/`.
- **Trigger**: The `SDD Agent` or `Documentador` should invoke this skill before closing a session that touched documentation.

## Instructions

### 1. Routing Table Synchronization Audit

Four documents contain overlapping routing/decision-tree information. After any change to one of them, verify that the others reflect the same intent-to-route mapping.

**Documents to cross-check:**

| Document | Section to Audit | Key Content |
|---|---|---|
| `workflows/orchestrate.md` | "Intent Fast Paths" table | Intent → Agent mapping |
| `context/orchestration/CHEATSHEET.md` | "Decision Tree" table (Step 6) | User intent → file → skill |
| `context/orchestration/AGENTS.md` | "Situational Shortcuts" table | Situation → file → reason |
| `context/orchestration/_TAG-INDEX.md` | "Fast Paths" table | Situation → recommended resource |

**Verification steps:**

1. Extract all intent/situation entries from each of the four tables.
2. For each unique intent (e.g., "Read-only question", "Fix a bug", "Review a PR"), verify that:
   - The **target agent** is consistent across all tables that mention it.
   - The **target file/doc** path is consistent (or at least not contradictory).
   - No table has an entry that is missing from the others without a valid reason (e.g., a table has a narrower scope by design).
3. Flag any discrepancy as a **SYNC ALERT**.

**SYNC ALERT format:**
```
🔗 SYNC ALERT — [Intent Name]
- Source: [document that has the correct/updated entry]
- Out of sync: [document(s) with stale or missing entry]
- Expected: [what the entry should say]
- Actual: [what the entry currently says]
```

### 2. Date Freshness (Stale Detection)

Scan all `.md` files in `.agents/` that contain `last_updated` in their frontmatter.

**Rules:**
- **Stale threshold**: `last_updated` older than **30 days** from the current date.
- **Critical stale**: `last_updated` older than **90 days** — flag for review or removal.
- **Missing frontmatter**: Files that should have `last_updated` but don't — flag for addition.

**Files exempt from stale check:**
- `cache-session/` contents (session-specific, not hub docs).
- `task-memory.md` (updated only when milestones occur, not on every session).

**Stale Alert format:**
```
📅 STALE ALERT — [file path]
- last_updated: [date]
- Age: [X days]
- Severity: [Warning (>30d) / Critical (>90d)]
- Action: [Update date if still valid / Review content / Archive if obsolete]
```

### 3. Link Integrity Check

For every relative markdown link (`[text](path)`) found in the four routing documents, verify that the target file exists.

**Scope:**
- All `.md` files in `context/orchestration/`.
- All `.md` files in `workflows/`.
- `skills/SKILLS_INDEX.md`.
- `AGENT-GUIDE.md`.

**Verification steps:**
1. Parse all relative links (ignore `http://` and `https://` URLs).
2. Resolve each link relative to the file's directory.
3. Check if the target file exists.
4. Flag broken links as **LINK ALERT**.

**LINK ALERT format:**
```
🔗 LINK ALERT — [source file]
- Broken link: [text](path)
- Resolved path: [absolute or relative resolved path]
- Status: File not found
```

## Decision Rules

- **Auto-fix allowed**: If a date is stale but the content is confirmed valid, update `last_updated` to the current date.
- **Never auto-fix routing**: If a routing table discrepancy is found, present the SYNC ALERT to the user and ask which version is correct. Do not guess.
- **Fail-fast on broken links**: A broken link in a routing document is a critical issue — the hub's navigation is compromised.

## Output Format

Return a **Sync Audit Report**:

```
## Sync Audit Report

### Routing Synchronization
- [ ] orchestrate.md ↔ CHEATSHEET.md
- [ ] orchestrate.md ↔ AGENTS.md
- [ ] orchestrate.md ↔ _TAG-INDEX.md
- [ ] CHEATSHEET.md ↔ AGENTS.md
- [ ] CHEATSHEET.md ↔ _TAG-INDEX.md
- [ ] AGENTS.md ↔ _TAG-INDEX.md

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

- **PROHIBITED**: Silently updating routing tables without user confirmation.
- **PROHIBITED**: Skipping the link integrity check — broken links break the entire navigation system.
- **MANDATORY**: Running this skill after any edit to the four routing documents.
- **MANDATORY**: Including the full Sync Audit Report in the session output.

## Examples

### Example 1: Clean Audit

**Sync Audit Report**

### Routing Synchronization
- [x] All 6 pairwise checks passed — no discrepancies.

Status: PASS

### Date Freshness
- Total files scanned: 42
- Stale files (>30d): 0
- Critical stale (>90d): 0
- Missing frontmatter: 0

Status: PASS

### Link Integrity
- Total links checked: 87
- Broken links: 0

Status: PASS

### Summary
Overall: PASS
Action Items: None

### Example 2: Discrepancy Found

**Sync Audit Report**

### Routing Synchronization
- [x] orchestrate.md ↔ CHEATSHEET.md
- [x] orchestrate.md ↔ AGENTS.md
- [ ] orchestrate.md ↔ _TAG-INDEX.md — **SYNC ALERT**
  - Intent: "Review a PR"
  - Source: `orchestrate.md` routes to `pr-reviewer` + `p2-review-analysis`
  - Out of sync: `_TAG-INDEX.md` only lists `github-pr-fetch.md` without skill reference
  - Expected: Add skill reference to match orchestrate.md
  - Actual: Missing skill column

Status: FAIL (1 SYNC ALERT)

### Date Freshness
- Total files scanned: 42
- Stale files (>30d): 1
  - 📅 STALE ALERT — `context/project/rules.md`
    - last_updated: 2026-04-14
    - Age: 25 days
    - Severity: Warning
    - Action: Update date if content is still valid

Status: WARNING (1 stale file)

### Link Integrity
- Total links checked: 87
- Broken links: 0

Status: PASS

### Summary
Overall: FAIL (routing discrepancy)
Action Items:
1. Update `_TAG-INDEX.md` Fast Paths table to include skill reference for PR review.
2. Confirm `rules.md` content is current and update `last_updated`.
