import { describe, it, expect, beforeEach, afterEach } from "bun:test"
import { resolveSnapshotDir, formatDateStamp } from "./snapshot"

describe("resolveSnapshotDir", () => {
  const originalEnv = { ...process.env }

  afterEach(() => {
    // Restore env
    for (const key of ["OPENCODE_HUMAN_ID", "USERNAME", "USER"]) {
      if (originalEnv[key] !== undefined) {
        process.env[key] = originalEnv[key]
      } else {
        delete process.env[key]
      }
    }
  })

  it("uses OPENCODE_HUMAN_ID when set", () => {
    process.env.OPENCODE_HUMAN_ID = "test-human"
    const ctx = { directory: "/projects/my-project" } as any
    const result = resolveSnapshotDir(ctx, "12072026")
    expect(result).toContain("test-human")
    expect(result).toContain("my-project")
    expect(result).toContain("12072026-runtime")
  })

  it("falls back to USERNAME when OPENCODE_HUMAN_ID is not set", () => {
    delete process.env.OPENCODE_HUMAN_ID
    process.env.USERNAME = "fallback-user"
    const ctx = { directory: "/projects/some-proj" } as any
    const result = resolveSnapshotDir(ctx, "01012026")
    expect(result).toContain("fallback-user")
    expect(result).toContain("some-proj")
  })

  it("falls back to USER when neither OPENCODE_HUMAN_ID nor USERNAME is set", () => {
    delete process.env.OPENCODE_HUMAN_ID
    delete process.env.USERNAME
    process.env.USER = "unix-user"
    const ctx = { directory: "/home/unix-user/code" } as any
    const result = resolveSnapshotDir(ctx, "25122026")
    expect(result).toContain("unix-user")
    expect(result).toContain("code")
  })

  it("uses 'unknown' when no env var is set", () => {
    delete process.env.OPENCODE_HUMAN_ID
    delete process.env.USERNAME
    delete process.env.USER
    const ctx = { directory: "/projects/test" } as any
    const result = resolveSnapshotDir(ctx, "01012026")
    expect(result).toContain("unknown")
  })

  it("includes .config/opencode/sessions in the path", () => {
    process.env.OPENCODE_HUMAN_ID = "test"
    const ctx = { directory: "/projects/test" } as any
    const result = resolveSnapshotDir(ctx, "01012026")
    expect(result).toContain(".config")
    expect(result).toContain("opencode")
    expect(result).toContain("sessions")
  })
})

describe("formatDateStamp", () => {
  it("returns a string in DDMMYYYY format", () => {
    const result = formatDateStamp()
    expect(result).toMatch(/^\d{8}$/)
  })
})
