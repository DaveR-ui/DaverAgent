import type { Plugin } from "@opencode-ai/plugin"

export function log(
  ctx: Parameters<Plugin>[0],
  level: "debug" | "info" | "error" | "warn",
  message: string,
  extra: Record<string, unknown>,
) {
  try {
    ctx.client.app.log({
      body: {
        service: "davercode-session-bridge",
        level,
        message,
        extra,
      },
    }).catch(() => {})
  } catch {
    // structured logging is best-effort
  }
}
