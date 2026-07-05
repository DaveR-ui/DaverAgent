# Agent Output Protocol

## Deprecation

> Este protocolo está **deprecado** desde la Etapa 3 del `agent-improvement-plan`.
>
> **Reemplazo nativo**: `GET /session/:id/children` devuelve `ChildInfo[]` con `status`, `summary`, `createdAt`, `durationMs` y `agentType` por cada subagent run.
>
> El cuerpo del archivo se conserva solo como referencia histórica del formato viejo.

This document defines how subagents write their outputs to disk to avoid overloading the orchestrator's context.

## Why this exists

When subagents return large outputs directly to the orchestrator, the orchestrator's context grows quickly:
- Its own reasoning
- Full outputs from N subagents
- File contents read during work
- Intermediate plans

This leads to: inflated context, higher cost, slower responses, and risk of hitting the context budget (250K-272K).

## The solution

Subagents write physical files to disk and return only a concise summary to the orchestrator.

```
Subagent → works → writes summary.md + output-full.md to disk
    ↓
Subagent → returns only summary (5-10 lines) to orchestrator
    ↓
Orchestrator → context stays small, reads files only when needed
```

## Directory structure

All outputs go to:
```
{session_path}/agents/{agent}-{timestamp}/
├── summary.md        # short report (same as returned to orchestrator)
└── output-full.md    # detailed report with diffs, logs, findings
```

The `{session_path}` is passed by the orchestrator when releasing the subagent.

## Manifest

Each session has a manifest file at `{session_path}/agents/manifest.md` that indexes all agent outputs.

Subagents append a row after completing their work:
```
| {agent} | {timestamp} | {task} | agents/{agent}-{timestamp}/summary.md | agents/{agent}-{timestamp}/output-full.md | {status} |
```

## What subagents must do

### 1. Return summary to orchestrator (in memory)

Return a concise summary (5-10 lines) with:
- What was done
- Key results
- Any blockers or questions

### 2. Write physical files to disk

Write two files to `{session_path}/agents/{agent}-{timestamp}/`:

**`summary.md`** — Short report (same content as returned to orchestrator)
```markdown
# {Agent} Output Summary
**Task**: <brief description>
**Status**: DONE | FAILED | PARTIAL
**Timestamp**: <ISO timestamp>

## Changes / Findings
- <item 1>
- <item 2>

## Results
- <test results, review verdict, exploration answer, etc.>

## Notes
- <any important context>
```

**`output-full.md`** — Detailed report with:
- Complete diffs or code changes
- Full test output / coverage report
- Error logs and stack traces
- Reasoning for decisions
- All findings with file paths and line numbers

### 3. Update manifest

Append a row to `{session_path}/agents/manifest.md`:
```
| {agent} | {timestamp} | {task} | agents/{agent}-{timestamp}/summary.md | agents/{agent}-{timestamp}/output-full.md | {status} |
```

## What orchestrator must do

### Before releasing subagents

1. Create the agents directory: `{session_path}/agents/`
2. Initialize the manifest: Copy `sessions/_templates/agent-manifest-template.md` to `{session_path}/agents/manifest.md`
3. Pass `session_path` to all subagents in the release prompt

### When receiving subagent responses

1. Receive only the summary (5-10 lines)
2. If details are needed, read the physical file from disk instead of asking the subagent to repeat

### In the final snapshot

Include the paths to agent outputs:
```markdown
## Agent outputs (on disk)
- Manifest: `{session_path}/agents/manifest.md`
- Coder: `{session_path}/agents/coder-{timestamp}/summary.md`
- Tester: `{session_path}/agents/tester-{timestamp}/summary.md`
```

## Permissions

All subagents need this permission to write to the sessions directory:
```yaml
permission:
  external_directory:
    "~/.config/opencode/sessions/**": allow
```

## Benefits

- **Context stays small**: Orchestrator sees only summaries
- **Full outputs preserved**: On disk for later reference
- **Selective reading**: Orchestrator reads specific files when needed
- **Parallel work**: Multiple subagents can work without inflating context
- **Traceability**: Physical record of what each agent did
