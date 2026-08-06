# Protocol: IA Search

Delegate live web searches and URL fetches to a connected subagent when the orchestrator itself is on an offline or restricted model. The protocol is a thin wrapper around a search / fetch subagent call.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-search`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to use

Trigger this protocol when:

- The task requires verifying external API documentation or latest library versions.
- The user provides URLs that need to be fetched and analyzed.
- The orchestrator needs to research best practices, patterns, or troubleshooting from external sources.
- Step 0 (interpret) or the [explorer](./ia-explorer.md) phase reveals a knowledge gap that local docs cannot fill.

Do NOT use this protocol when:

- The answer can be found in local `docs/context/` documentation.
- The query is about internal project structure or codebase patterns.
- The task is purely local code analysis or refactoring.

## How to delegate

Structure the delegation request clearly before invoking the search subagent:

```
Search Type: [websearch | webfetch | both]
Query / URL: [specific search terms or target URLs]
Context: [brief background from the current orchestration phase]
Expected Output: [what format or information is needed]
```

In the opencode runtime, the [external-scout subagent](../agents/subagents/external-scout.md) is the canonical fetcher; for one-off URL fetches the `webfetch` tool is also available.

## Consume the results

The search subagent returns a structured report. Integrate findings into the current phase:

- **Initiation / analyzer** — use findings to clarify success criteria or constraints.
- **Exploration / explorer** — use findings to expand scope understanding or validate external dependencies.
- **Supply / supplier** — use findings as additional context delta.
- **Proposal / proposer** — reference external patterns or best practices in the implementation plan.

## Cross-reference with local context

After receiving results:

- Check if external findings align with local `docs/context/` documentation.
- Flag any contradictions between external sources and local standards.
- Note if local docs should be updated based on new external information.

## Decision rules

- **MANDATORY**: always specify the exact search query or URL — never delegate vague requests.
- **MANDATORY**: limit to 3 concurrent search delegations per orchestration cycle to avoid context overload.
- **PROHIBITED**: do not delegate implementation tasks to the search subagent — it is read-only research.
- **PROHIBITED**: do not assume search results are authoritative — always note confidence level.
- **PRIORITY**: prefer local `docs/context/` docs when available; use web search only for gaps or updates.

## Output integration

When search results are received, add them to the session context:

```markdown
## External Research Results

**Source**: external-scout subagent
**Query**: {original query}
**Confidence**: {High / Medium / Low}

**Key Findings**:
- {Finding 1 with source}
- {Finding 2 with source}

**Integration Notes**:
- {How this affects the current orchestration phase}
- {Any contradictions with local docs}
```

## Constraints

- **Timeout** — search invocations should complete within 60 seconds; if not, report partial results.
- **Rate limit** — maximum 5 search queries per invocation.
- **Language** — results should be synthesized in English for AI consumption, with source URLs preserved.
- **Attribution** — every finding must include the source URL for verification.

## Integration

The [external-scout subagent](../agents/subagents/external-scout.md) is the opencode-native equivalent. Use this protocol when the orchestrator wants the results framed as a Context-Supply delta (rather than a raw fetch) — that is, with explicit cross-reference back to local `docs/context/`. The [supplier](./ia-supplier.md) protocol then incorporates the delta into the context package delivered to the [proposer](./ia-proposer.md).
