import { describe, it, expect } from "bun:test"
import { SessionSnapshotSchema } from "./schema"

describe("SessionSnapshotSchema", () => {
  const validPayload = {
    schemaVersion: "1.0",
    generatedBy: "davercode-session-bridge" as const,
    generatedAt: new Date().toISOString(),
    sessionID: "sess_123",
    eventType: "session.idle",
    projectSlug: "my-project",
    humanID: "test-human",
    status: "idle" as const,
    extra: { key: "value" },
  }

  it("accepts a valid payload", () => {
    const result = SessionSnapshotSchema.safeParse(validPayload)
    expect(result.success).toBe(true)
  })

  it("accepts status 'error'", () => {
    const result = SessionSnapshotSchema.safeParse({ ...validPayload, status: "error" })
    expect(result.success).toBe(true)
  })

  it("accepts status 'completed'", () => {
    const result = SessionSnapshotSchema.safeParse({ ...validPayload, status: "completed" })
    expect(result.success).toBe(true)
  })

  it("rejects invalid status", () => {
    const result = SessionSnapshotSchema.safeParse({ ...validPayload, status: "unknown" })
    expect(result.success).toBe(false)
  })

  it("rejects missing sessionID", () => {
    const { sessionID, ...invalid } = validPayload
    const result = SessionSnapshotSchema.safeParse(invalid)
    expect(result.success).toBe(false)
  })

  it("rejects wrong generatedBy literal", () => {
    const result = SessionSnapshotSchema.safeParse({ ...validPayload, generatedBy: "other-plugin" })
    expect(result.success).toBe(false)
  })

  it("rejects missing extra field", () => {
    const { extra, ...invalid } = validPayload
    const result = SessionSnapshotSchema.safeParse(invalid)
    expect(result.success).toBe(false)
  })
})
