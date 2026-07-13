import { tool } from "@opencode-ai/plugin"

export const SessionSnapshotSchema = tool.schema.object({
  schemaVersion: tool.schema.string(),
  generatedBy: tool.schema.literal("davercode-session-bridge"),
  generatedAt: tool.schema.string(),
  sessionID: tool.schema.string(),
  eventType: tool.schema.string(),
  projectSlug: tool.schema.string(),
  humanID: tool.schema.string(),
  status: tool.schema.enum(["idle", "error", "completed"]),
  extra: tool.schema.record(tool.schema.string(), tool.schema.unknown()),
})
