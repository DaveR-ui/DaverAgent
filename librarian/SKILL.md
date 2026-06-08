---
name: librarian
description: >
  A librarian skill that manages documentation across multiple topics.
  Use this skill whenever the user asks questions about Angular, Opencode,
  or VSCode, or wants to search, reference, or synthesize information from
  stored documentation. The librarian dispatches to specialized sub-agents
  per topic and returns a structured response with cited sources.
  Trigger when the user mentions any of these topics, asks for documentation
  lookup, or wants information synthesized from reference materials.
---

# Librarian

## Overview

The librarian is a documentation manager that:

1. Maintains an index of available topics and their resources
2. Dispatches queries to specialized sub-agents per topic
3. Returns a structured, synthesized response with source citations

## Topic Index

| Topic      | Agent                    | Resources Location        |
|------------|--------------------------|---------------------------|
| Angular    | `agents/angular-agent.md`| `resources/angular/`      |
| Opencode   | `agents/opencode-agent.md`| `resources/opencode/`     |
| VSCode     | `agents/vscode-agent.md` | `resources/vscode/`       |

To add a new topic:
1. Create a folder under `resources/<topic>/`
2. Add an `INDEX.md` inside that folder listing its sub-folders and files
3. Create a sub-agent at `agents/<topic>-agent.md`
4. Add an entry to the table above

## Workflow

### Step 1: Identify the topic

Read the user's query and determine which topic(s) are relevant.
If multiple topics apply, dispatch to all relevant sub-agents.

### Step 2: Dispatch to the sub-agent

For each relevant topic:
1. Read the sub-agent file at `agents/<topic>-agent.md`
2. Read the topic's `resources/<topic>/INDEX.md` to understand available resources
3. Follow the sub-agent's instructions to answer the query using the resources

Each sub-agent contains its own search strategy explaining how to navigate the documentation structure. The sub-agent will:
- Start by reading the root `INDEX.md` of its topic folder
- Navigate to the relevant sub-folder using its `index.md`
- Read only the specific files needed to answer the query

### Step 3: Synthesize the response

Combine the sub-agent outputs into a single structured response:

```
# [Topic] — [Brief Title]

## Answer
[Synthesized answer to the user's question]

## Sources
- [File name](relative/path) — [brief note on what this source covers]
- ...

## Notes
[Any additional context, caveats, or follow-up suggestions]
```

If the user specified an output format, adapt the response to match it.

## Adding New Topics

When adding a new topic, follow this checklist:

- [ ] Create `resources/<topic>/` directory
- [ ] Create `resources/<topic>/INDEX.md` listing all sub-folders and their contents
- [ ] Create sub-folders for each sub-topic with their own `index.md`
- [ ] Create `agents/<topic>-agent.md` with instructions for the sub-agent, including search strategy
- [ ] Update the Topic Index table in this file
- [ ] Test the new topic with a sample query
