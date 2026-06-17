# humano.md Policy

## Source vs Copy

| File | Location | Rule |
|------|----------|------|
| **Source** | `humans/{human_id}/humano.md` | Master copy. Edit here, then sync. |
| **Sessions copy** | `sessions/{human_id}/humano.md` | Exact copy. Never edit directly. |

## Dictionary Structure

The dictionary has TWO sections:
1. **Slang/Colloquialisms** - how the human talks in their language
2. **Technical Terms** - project-specific jargon the human uses

## Dictionary Rules

- Dictionary is for **TRANSLATION only**, not style matching
- The agent does NOT imitate the human's colloquialisms
- Agent speaks in neutral/professional tone in the human's language
- If a term is about the **project domain**, it goes in `project.md` (Project Slang)
- If a term is about **how this human talks**, it goes in `humano.md`

## Health Thresholds

| Term Count | Status | Action |
|------------|--------|--------|
| 0-50 | Compact (OK) | Continue adding |
| 51-100 | Growing | Be selective |
| 101+ | Large | Alert human, suggest pruning |
