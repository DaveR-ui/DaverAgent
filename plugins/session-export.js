// session-export.js - publish opencode session list + status to a JSON file.
//
// PURPOSE
//   An external KDE Plasma widget polls a single JSON file to render the active
//   opencode session list and each session's run state. This plugin keeps that
//   file fresh: on every `event`, `chat.message`, and `tool.execute.after` it
//   asks the LOCAL opencode server for the session list and the status map and
//   writes a normalized snapshot. It reads no credentials, sends no model
//   override, and talks only to the local server through `ctx.client`.
//
// OUTPUT LOCATION (global, per machine - NOT per worktree)
//   Default: $XDG_STATE_HOME/opencode/sessions.json
//   Fallback: ~/.local/state/opencode/sessions.json
//   Rationale: runtime state belongs in the state dir, OUTSIDE the tracked
//   config git repo, so it never pollutes `git status`.
//   Override:    OPENCODE_SESSION_EXPORT (absolute path).
//   Kill switch: OPENCODE_SESSION_EXPORT_DISABLE=1 disables all action.
//
// FILE FORMAT (UTF-8 JSON)
//   {
//     "updatedAt": "2026-09-13T22:30:00.000Z",
//     "sessions": [
//       {"id":"ses_...","title":"...","parentID":null,
//        "status":"idle","updated":1757800200000}
//     ]
//   }
//   - `status` is exactly "idle" | "busy" | "retry", else "unknown" when the
//     server cannot tell.
//   - `updated` is epoch ms from `session.time.updated` (fallback
//     `session.time.created`, else 0).
//   - `parentID` is null for top-level sessions (`session.parentID ?? null`).
//   - Sessions are sorted by status rank (busy, retry, idle, unknown), then by
//     `updated` descending, then by `id` ascending for determinism.
//
// ATOMIC WRITE
//   The snapshot is written to a temp file in the SAME directory and then
//   `fs.rename`d over the target, so a reader never observes partial JSON. A
//   failed write removes the temp file best-effort and leaves the previous
//   snapshot untouched.
//
// SAFE / NO-THROW POLICY
//   Hooks return immediately and never await fs or network; refreshes are
//   single-flight and rate-limited to one every MIN_INTERVAL_MS. If `ctx.client`
//   is absent or `session.list()` fails/errors, nothing is written and the
//   previous snapshot is left untouched (inert when the server is unreachable).
//   If `session.list()` succeeds but `session.status()` fails, a valid snapshot
//   is still written with every status set to "unknown". An empty session list
//   is valid and produces a fresh `updatedAt` with `"sessions": []`. Nothing
//   throws upward.
import { promises as fs } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

const DEFAULT_FILENAME = "sessions.json";
const MIN_INTERVAL_MS = 400;
const STATUS_RANK = { busy: 0, retry: 1, idle: 2, unknown: 3 };

export const server = async (ctx) => {
  // --- closure state -------------------------------------------------------
  let activeSessionID = "";
  let refreshing = false;
  let dirty = false;
  let lastCheck = 0;
  let retryTimer = null;

  function log(message) {
    try {
      console.error(`[session-export] ${message}`);
    } catch {
      // Logging must never throw.
    }
  }

  function getString(value) {
    return typeof value === "string" && value.length > 0 ? value : "";
  }

  function isDisabled() {
    try {
      return process.env.OPENCODE_SESSION_EXPORT_DISABLE === "1";
    } catch {
      return false;
    }
  }

  function exportPath() {
    const override = process.env.OPENCODE_SESSION_EXPORT;
    if (typeof override === "string" && override.length > 0) return override;
    const stateHome = process.env.XDG_STATE_HOME;
    const base =
      typeof stateHome === "string" && stateHome.length > 0
        ? stateHome
        : path.join(homedir(), ".local", "state");
    return path.join(base, "opencode", DEFAULT_FILENAME);
  }

  function extractSessionID(event) {
    const p = event?.properties;
    const direct =
      getString(p?.sessionID) ||
      getString(p?.sessionId) ||
      getString(p?.session_id) ||
      getString(event?.sessionID) ||
      getString(event?.sessionId) ||
      getString(event?.session_id);
    if (direct) return direct;

    const nested =
      getString(p?.info?.sessionID) ||
      getString(p?.info?.sessionId) ||
      getString(p?.info?.session_id);
    if (nested) return nested;

    // Only session.* events carry the session id in `info.id`; for message/part
    // events `info.id` is a message id and must never be treated as a session.
    if (getString(event?.type).startsWith("session.")) {
      return getString(p?.info?.id) || getString(p?.id);
    }
    return "";
  }

  function trackFromInput(input) {
    const id =
      getString(input?.sessionID) ||
      getString(input?.sessionId) ||
      getString(input?.session_id);
    if (id) activeSessionID = id;
  }

  function unwrap(result) {
    if (result && typeof result === "object" && result.error) {
      const error =
        typeof result.error === "string" ? result.error : JSON.stringify(result.error);
      throw new Error(error);
    }
    return result && typeof result === "object" && "data" in result ? result.data : result;
  }

  function statusOf(statusMap, id) {
    const type =
      statusMap && typeof statusMap === "object" && id ? statusMap[id]?.type : undefined;
    return type === "idle" || type === "busy" || type === "retry" ? type : "unknown";
  }

  function buildSnapshot(sessions, statusMap) {
    const rows = (Array.isArray(sessions) ? sessions : []).map((session) => {
      const updated = session?.time?.updated;
      const created = session?.time?.created;
      return {
        id: getString(session?.id),
        title: typeof session?.title === "string" ? session.title : "",
        parentID: session?.parentID ?? null,
        status: statusOf(statusMap, session?.id),
        updated: Number.isFinite(updated) ? updated : Number.isFinite(created) ? created : 0,
      };
    });

    rows.sort((a, b) => {
      const rankA = STATUS_RANK[a.status] ?? 3;
      const rankB = STATUS_RANK[b.status] ?? 3;
      if (rankA !== rankB) return rankA - rankB;
      if (a.updated !== b.updated) return b.updated - a.updated;
      return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
    });

    return { updatedAt: new Date().toISOString(), sessions: rows };
  }

  async function writeSnapshot(payload) {
    const target = exportPath();
    const tmp = `${target}.${process.pid}.${Date.now()}.tmp`;
    try {
      await fs.mkdir(path.dirname(target), { recursive: true });
      await fs.writeFile(tmp, JSON.stringify(payload, null, 2), "utf8");
      await fs.rename(tmp, target);
    } catch (error) {
      try {
        await fs.rm(tmp, { force: true });
      } catch {
        // Best-effort cleanup; the original error is the useful one.
      }
      throw error;
    }
  }

  async function refresh() {
    if (isDisabled()) return;

    const client = ctx?.client;
    if (!client?.session || typeof client.session.list !== "function") return;

    let sessions;
    try {
      sessions = unwrap(await client.session.list());
    } catch (error) {
      // Unreachable server / list error: leave the previous snapshot untouched.
      log(`session.list failed: ${error instanceof Error ? error.message : String(error)}`);
      return;
    }

    let statusMap = {};
    try {
      statusMap = unwrap(await client.session.status()) ?? {};
    } catch (error) {
      // Status is optional: still export a valid snapshot with unknown statuses.
      log(
        `session.status failed; exporting unknown statuses: ${error instanceof Error ? error.message : String(error)}`,
      );
      statusMap = {};
    }

    const payload = buildSnapshot(sessions, statusMap);
    try {
      await writeSnapshot(payload);
      log(
        `exported ${payload.sessions.length} session(s) to ${exportPath()} (active ${activeSessionID || "none"})`,
      );
    } catch (error) {
      log(`write failed: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // --- non-blocking single-flight scheduling -------------------------------
  function scheduleRefresh() {
    if (isDisabled()) return;
    if (refreshing) {
      dirty = true;
      return;
    }
    const now = Date.now();
    const elapsed = now - lastCheck;
    if (elapsed < MIN_INTERVAL_MS) {
      dirty = true;
      if (!retryTimer) {
        retryTimer = setTimeout(() => {
          retryTimer = null;
          const pending = dirty;
          dirty = false;
          if (pending) scheduleRefresh();
        }, MIN_INTERVAL_MS - elapsed);
        if (retryTimer && typeof retryTimer.unref === "function") retryTimer.unref();
      }
      return;
    }
    dirty = false;
    lastCheck = now;
    refreshing = true;
    Promise.resolve()
      .then(refresh)
      .catch((error) =>
        log(`refresh failed: ${error instanceof Error ? error.message : String(error)}`),
      )
      .finally(() => {
        refreshing = false;
        if (dirty) scheduleRefresh();
      });
  }

  return {
    event: async ({ event }) => {
      try {
        const id = extractSessionID(event);
        if (id) activeSessionID = id;
        scheduleRefresh();
      } catch (error) {
        log(`event hook failed: ${error instanceof Error ? error.message : String(error)}`);
      }
    },
    "chat.message": async (input) => {
      try {
        trackFromInput(input);
        scheduleRefresh();
      } catch (error) {
        log(`chat.message hook failed: ${error instanceof Error ? error.message : String(error)}`);
      }
    },
    "tool.execute.after": async (input) => {
      try {
        trackFromInput(input);
        scheduleRefresh();
      } catch (error) {
        log(
          `tool.execute.after hook failed: ${error instanceof Error ? error.message : String(error)}`,
        );
      }
    },
  };
};
