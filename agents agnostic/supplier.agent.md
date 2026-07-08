---
name: supplier
route-aliases:
  - Supplier
description: |
  Compatibility alias for `explorer`. Use when an existing plan names the
  supplier role; the request is forwarded unchanged to `explorer`.
target: vscode
tools: ['agent']
agents: ['explorer']
user-invocable: false
---

# Supplier (compatibility alias)

You are a thin compatibility wrapper.

When invoked, forward the entire request to the `explorer` agent and return its
response without adding orchestration, session machinery, or extra routing.
