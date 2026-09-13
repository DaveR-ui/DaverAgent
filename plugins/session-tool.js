// session-tool.js - opencode session inspection / continuation tool.
//
// Exposes a single `session` tool with the ops:
//   children | tree | parent | messages | status | todo | diff | send
//
// Read ops (children/tree/parent/messages/status/todo/diff) default to the
// caller's own session and are available to any agent. `send` — which prompts
// another session and therefore has side effects — is restricted to
// `orchestrator` and `delivery` and is gated behind `ctx.ask`.
//
// The plugin closes over `ctx.client` (the SDK client) in `server(ctx)`; the
// tool's `execute` receives the per-call ToolContext (sessionID, agent, ask).
import { tool } from "@opencode-ai/plugin";

const OPS = ["children", "tree", "parent", "messages", "status", "todo", "diff", "send"];
const SEND_AGENTS = new Set(["orchestrator", "delivery"]);

function render(value) {
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value, null, 2);
  } catch {
    return String(value);
  }
}

function unwrap(result) {
  if (result && typeof result === "object" && result.error) {
    const error =
      typeof result.error === "string" ? result.error : JSON.stringify(result.error);
    throw new Error(error);
  }
  return result && typeof result === "object" && "data" in result ? result.data : result;
}

function summarize(session) {
  if (!session) return null;
  return {
    id: session.id,
    parentID: session.parentID ?? null,
    title: session.title,
    time: session.time,
  };
}

export const server = async (ctx) => {
  const client = ctx.client;

  return {
    tool: {
      session: tool({
        description:
          "Inspect or continue an opencode session. Ops: children (direct child sessions), tree (recursive descendants), parent (lineage), messages (recent messages), status (run-state map), todo (todo list), diff (files changed), send (prompt a session; orchestrator|delivery only). Target defaults to the current session.",
        args: {
          op: tool.schema.enum(OPS).describe("Operation to run."),
          sessionID: tool.schema
            .string()
            .optional()
            .describe("Target session id; defaults to the current session."),
          message: tool.schema
            .string()
            .optional()
            .describe("Required for op=send: the prompt text to deliver to the session."),
          limit: tool.schema
            .number()
            .optional()
            .describe("Max results for op=messages (default 20)."),
          depth: tool.schema
            .number()
            .optional()
            .describe("Max depth for op=tree (default 3)."),
        },
        async execute(args, toolCtx) {
          const target = args.sessionID || toolCtx.sessionID;

          try {
            switch (args.op) {
              case "children": {
                const res = await client.session.children({ path: { id: target } });
                const children = (unwrap(res) ?? []).map(summarize);
                return `children of ${target} (${children.length}):\n${render(children)}`;
              }
              case "parent": {
                const res = await client.session.get({ path: { id: target } });
                const parentID = unwrap(res)?.parentID;
                if (!parentID) return `session ${target} has no parent (root session).`;
                const parent = await client.session.get({ path: { id: parentID } });
                return `parent of ${target}:\n${render(summarize(unwrap(parent)))}`;
              }
              case "status": {
                const res = await client.session.status();
                return `session status map:\n${render(unwrap(res) ?? {})}`;
              }
              case "todo": {
                const res = await client.session.todo({ path: { id: target } });
                return `todo for ${target}:\n${render(unwrap(res) ?? [])}`;
              }
              case "diff": {
                const res = await client.session.diff({ path: { id: target } });
                return `diff for ${target}:\n${render(unwrap(res) ?? [])}`;
              }
              case "messages": {
                const res = await client.session.messages({
                  path: { id: target },
                  query: { limit: args.limit ?? 20 },
                });
                return `messages for ${target}:\n${render(unwrap(res) ?? [])}`;
              }
              case "tree": {
                const maxDepth = args.depth ?? 3;
                const lines = [`${target} (root of tree)`];
                const walk = async (id, level) => {
                  const res = await client.session.children({ path: { id } });
                  for (const child of unwrap(res) ?? []) {
                    lines.push(`${"  ".repeat(level)}- ${child.id} — ${child.title ?? ""}`);
                    if (level < maxDepth) await walk(child.id, level + 1);
                  }
                };
                await walk(target, 1);
                return lines.join("\n");
              }
              case "send": {
                if (!SEND_AGENTS.has(toolCtx.agent)) {
                  return `session send is restricted to orchestrator|delivery (current agent: ${toolCtx.agent}).`;
                }
                if (!args.message) return "op=send requires a `message`.";
                await toolCtx.ask({
                  permission: "session_send",
                  patterns: [target],
                  always: [],
                  metadata: { sessionID: target, agent: toolCtx.agent },
                });
                const res = await client.session.prompt({
                  path: { id: target },
                  body: { parts: [{ type: "text", text: args.message }] },
                });
                return `sent to ${target}:\n${render(unwrap(res) ?? {})}`;
              }
              default:
                return `unknown op: ${args.op}`;
            }
          } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return `session ${args.op} failed: ${message}`;
          }
        },
      }),
    },
  };
};
