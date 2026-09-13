---
description: Inspect or continue an opencode session (children, tree, parent, messages, status, todo, diff, send)
agent: orchestrator
---
Use the `session` tool exactly once to inspect the opencode session named in the arguments.

Arguments: `$ARGUMENTS`

Parse the arguments as `<session-id> [op] [extra]`:

- `session-id` — the target session id (omit to inspect the current session).
- `op` — one of `children`, `tree`, `parent`, `messages`, `status`, `todo`, `diff`, `send` (default: `tree`).
- `extra` — for `op=send`, the remaining text is the message to deliver; for `op=messages`, an optional numeric limit.

Call `session` with `sessionID` and `op`, then report the result compactly (paths/session ids verbatim, no narration). Do not edit any file. If the session cannot be read, say so in one line and stop.
