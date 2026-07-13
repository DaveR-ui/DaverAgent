import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"
import { log } from "./logger"
import { writeSessionSnapshot } from "./snapshot"

export const plugin: Plugin = async (ctx) => {
  return {
    event: async (input) => {
      const event = input.event

      if (event.type === "session.created") {
        return log(ctx, "info", "session created", {
          sessionID: event.properties.info.id,
          title: event.properties.info.title,
        })
      }

      if (event.type === "session.idle") {
        await writeSessionSnapshot(ctx, event.properties.sessionID, "idle", event.properties)
        return log(ctx, "info", "session idle", {
          sessionID: event.properties.sessionID,
        })
      }

      if (event.type === "session.error") {
        const sessionID = event.properties.sessionID ?? "unknown"
        await writeSessionSnapshot(ctx, sessionID, "error", event.properties)
        return log(ctx, "error", "session error", {
          sessionID,
          errorType: typeof event.properties.error,
        })
      }

      if (event.type === "session.compacted") {
        return log(ctx, "info", "session compacted", {
          sessionID: event.properties.sessionID,
        })
      }
    },
    tool: {
      session_status: tool({
        description: "List recent opencode sessions with a compact summary",
        args: {
          limit: tool.schema.number().optional().describe("Max sessions to return, defaults to 10"),
        },
        async execute(args, context) {
          try {
            const response = await ctx.client.session.list()
            const sessions = response.data ?? []
            const limit = args.limit ?? 10
            const lines = sessions.slice(0, limit).map((s) => {
              return `${s.id} | ${s.title} | ${new Date(s.time.created).toISOString()}`
            })
            return lines.join("\n")
          } catch (error) {
            const reason = error instanceof Error ? error.message : String(error)
            return `Failed to list sessions: ${reason}`
          }
        },
      }),
    },
  }
}
