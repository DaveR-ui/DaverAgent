---
name: web-search-delegate
description: Standardized skill for delegating web searches to the WebSearch subagent. Enables offline models (like Qwen3.6) to perform internet research through a connected agent.
last_updated: 2026-04-30
status: active
---

# 🌐 Skill: Web Search Delegate

## Goal
Enable any orchestrator agent (especially those without native internet connectivity like Qwen3.6) to perform live web searches and fetch external URLs by delegating to the `WebSearch` subagent with model `minimax/minimax-m2:7b`.

## When to Use

Trigger this skill when:
- The task requires verifying external API documentation or latest library versions
- The user provides URLs that need to be fetched and analyzed
- The orchestrator needs to research best practices, patterns, or troubleshooting from external sources
- Phase 1 (Initiation) or Phase 2 (Exploration) reveals a knowledge gap that local docs cannot fill

Do NOT use this skill when:
- The answer can be found in local `.agents/context/` documentation
- The query is about internal project structure or codebase patterns
- The task is purely local code analysis or refactoring

## Instructions

### 1. Prepare the Delegation Request

Before invoking the `WebSearch` subagent, structure the request clearly:

```
Search Type: [websearch | webfetch | both]
Query/URL: [specific search terms or target URLs]
Context: [brief background from the current SDD phase]
Expected Output: [what format or information is needed]
```

### 2. Invoke the WebSearch Subagent

Use the `task` tool with the following parameters:

```
tool: task
subagent_type: WebSearch
prompt: [structured delegation request from step 1]
```

### 3. Consume the Results

The `WebSearch` agent will return a structured report. Integrate findings into the current phase:

- **Phase 1 (Initiation)**: Use findings to clarify success criteria or constraints
- **Phase 2 (Exploration)**: Use findings to expand scope understanding or validate external dependencies
- **Phase 3 (Context Supply)**: Use findings as additional context delta
- **Phase 4 (Proposal)**: Reference external patterns or best practices in the implementation plan

### 4. Cross-Reference with Local Context

After receiving results:
- Check if external findings align with local `.agents/context/` documentation
- Flag any contradictions between external sources and local standards
- Note if local docs should be updated based on new external information

## Decision Rules

- **MANDATORY**: Always specify the exact search query or URL — never delegate vague requests
- **MANDATORY**: Limit to 3 concurrent search delegations per SDD cycle to avoid context overload
- **PROHIBITED**: Do not delegate implementation tasks to WebSearch — it is read-only research
- **PROHIBITED**: Do not assume WebSearch results are authoritative — always note confidence level
- **PRIORITY**: Prefer local `.agents/context/` docs when available; use web search only for gaps or updates

## Output Integration

When WebSearch results are received, add them to the session context:

```markdown
## External Research Results (WebSearch Delegate)

**Source**: WebSearch subagent (minimax/minimax-m2:7b)
**Query**: {original query}
**Confidence**: {High/Medium/Low}

**Key Findings**:
- {Finding 1 with source}
- {Finding 2 with source}

**Integration Notes**:
- {How this affects the current SDD phase}
- {Any contradictions with local docs}
```

## Examples

### Example 1: API Documentation Lookup

**Orchestrator Request**:
```
Search Type: websearch
Query: "Angular v21 rxResource signal API latest patterns"
Context: Phase 2 Exploration — need to verify current best practices for reactive resource loading
Expected Output: Code patterns and official API reference
```

### Example 2: URL Fetch and Analysis

**Orchestrator Request**:
```
Search Type: webfetch
URL: "https://github.com/angular/angular/issues/12345"
Context: Phase 1 Initiation — user referenced this issue as related to the bug
Expected Output: Issue description, reproduction steps, and any official resolution
```

### Example 3: Combined Search

**Orchestrator Request**:
```
Search Type: both
Query: "AG Grid row selection API v32"
URL: "https://www.ag-grid.com/documentation/javascript/row-selection/"
Context: Phase 4 Proposal — need to validate implementation approach against latest API
Expected Output: Current API methods and any breaking changes from previous versions
```

## Constraints

- **TIMEOUT**: WebSearch invocations should complete within 60 seconds; if not, report partial results
- **RATE LIMIT**: Maximum 5 search queries per invocation
- **LANGUAGE**: Results should be synthesized in English for AI consumption, with source URLs preserved
- **ATTRIBUTION**: Every finding must include source URL for verification