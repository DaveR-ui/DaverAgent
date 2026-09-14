// steer-inbox.js - file-based steering inbox for opencode sessions.
//
// PURPOSE
//   The human appends one JSON object per line (JSONL) to a per-machine inbox
//   file while an agent turn is running. This plugin tails that file and
//   delivers each message to the active session over the v2 steer channel
//   (`delivery: "steer"`), which is promoted at the next step boundary and
//   applied within the same turn.
//
// SAFE PROVIDER POLICY
//   This plugin sends NO model override. The target session therefore uses its
//   own already-available default model (the default Zen model). It NEVER reads
//   credentials or secrets and NEVER auto-connects any integration. A user who
//   wants to run on `opencode-go/deepseek-v4.1-flash` must manually connect the
//   `opencode-go` integration once (one-time, via the normal opencode auth
//   flow); after that a session may select it in its own configuration. Nothing
//   here does that for you.
//
// INBOX LOCATION (global, per machine - NOT per worktree)
//   Default: $XDG_STATE_HOME/opencode/steer-inbox.jsonl
//   Fallback: ~/.local/state/opencode/steer-inbox.jsonl
//   Rationale: runtime state belongs in the state dir, OUTSIDE the tracked
//   config git repo, so it never pollutes `git status`.
//   Override:    OPENCODE_STEER_INBOX (absolute path).
//   Kill switch: OPENCODE_STEER_INBOX_DISABLE=1 disables all action.
//   Ack sidecar: <inbox>.offset (plain byte-count string).
//
// CROSS-PROCESS LIMITATION
//   The inbox path is global per machine and there is NO cross-process lock.
//   Two opencode instances on the same machine can race on <inbox>.offset and
//   double-steer or skip lines. Run a single instance per machine, or give each
//   instance a distinct OPENCODE_STEER_INBOX path.
//
// LINE FORMAT (one JSON object per line)
//   {"text":"...", "session":"ses_..."}
//   - `text`    required, non-empty.
//   - `session` OR `target` optional explicit destination session.
//   Malformed / empty / missing-text lines are skipped, logged, and acked so
//   they can never block later messages. A valid line with no resolvable target
//   (no explicit session AND no known active session) is NOT acked: processing
//   stops at that line and leaves it (and everything after it) for a later drain.
//
// ACK MECHANISM (at-most-once within a process)
//   Only complete newline-terminated lines are processed; a trailing partial
//   line is left for next time. After each fully processed line the byte offset
//   is advanced to that line's end and persisted (async) to <inbox>.offset. An
//   in-memory fallback offset is kept too, so an unreadable or unwritable offset
//   file cannot cause unbounded re-delivery within the process. Semantics are
//   at-most-once: a line is steered once within a running process, but a crash
//   between admission and the offset write can cause ONE re-delivery after
//   restart. Delivery errors are logged and the line is still acked (no retry
//   storm).
//
// SESSION ROUTING
//   The most-recently-active session id is tracked from `event`, `chat.message`
//   and `tool.execute.after`. Lines with an explicit `session`/`target` route
//   there. When multiple sessions are active and no explicit target is given,
//   the most-recently-active session wins (documented ambiguity).
//
// OPT-IN / INERT BY DEFAULT
//   If the inbox file does not exist, the plugin is completely inert: an async
//   stat returns ENOENT and the drain is a no-op. Create the file to opt in.
//
// NON-BLOCKING
//   Hooks return immediately and never await fs or network. Drains are single-
//   flight and rate-limited to one every MIN_INTERVAL_MS; a pending append that
//   arrives during the throttle window is re-scheduled via a bounded one-shot
//   timer so a trigger is not lost. Nothing throws upward.
import { promises as fs } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

const DEFAULT_FILENAME = "steer-inbox.jsonl";
const MIN_INTERVAL_MS = 400;

export const server = async (ctx) => {
  // --- closure state -------------------------------------------------------
  let activeSessionID = "";
  let cachedOffset = 0;
  let draining = false;
  let dirty = false;
  let lastCheck = 0;
  let retryTimer = null;

  function log(message) {
    try {
      console.error(`[steer-inbox] ${message}`);
    } catch {
      // Logging must never throw.
    }
  }

  function getString(value) {
    return typeof value === "string" && value.length > 0 ? value : "";
  }

  function isDisabled() {
    try {
      return process.env.OPENCODE_STEER_INBOX_DISABLE === "1";
    } catch {
      return false;
    }
  }

  function inboxPath() {
    const override = process.env.OPENCODE_STEER_INBOX;
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

  // --- delivery layering (each guarded; caller catches) --------------------
  async function deliverSteer(ctx, targetSessionID, text) {
    // Layer 1 - speculative forward-compat shim. NOT present on the v1 client in
    // 1.18.x (ctx.client has no `.v2`); kept only in case a future SDK exposes it.
    const direct = ctx?.client?.v2?.session?.prompt;
    if (typeof direct === "function") {
      return direct.call(ctx.client.v2.session, {
        sessionID: targetSessionID,
        prompt: { text },
        delivery: "steer",
      });
    }

    // Layer 2 - the installed @opencode-ai/sdk/v2. The import/construction is
    // hoisted OUT of the call so Layer 3 is only a fallback for an *unavailable*
    // SDK, never for a failed (possibly already-admitted) request.
    let createClient = null;
    try {
      const mod = await import("@opencode-ai/sdk/v2");
      createClient = mod.createOpencodeClient;
    } catch {
      createClient = null;
    }
    if (typeof createClient === "function") {
      const client = createClient({ baseUrl: String(ctx.serverUrl), throwOnError: true });
      // The v2 steer route lives under the `v2` namespace and POSTs to
      // /api/session/{sessionID}/prompt with body { id?, prompt, delivery?, resume? }.
      const result = await client.v2.session.prompt({
        sessionID: targetSessionID,
        prompt: { text },
        delivery: "steer",
      });
      if (result && typeof result === "object" && result.error) {
        throw new Error("steer rejected by server");
      }
      return result;
    }

    // Layer 3 - raw HTTP fallback (same endpoint the live spike verified). Runs
    // only when the SDK is unavailable, never after a possibly-admitted failure.
    const base = String(ctx?.serverUrl || "").replace(/\/+$/, "");
    if (!base) throw new Error("no serverUrl available for steer");
    const res = await fetch(`${base}/api/session/${encodeURIComponent(targetSessionID)}/prompt`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ prompt: { text }, delivery: "steer" }),
    });
    if (!res.ok) throw new Error(`steer HTTP ${res.status}`);
    return res.json().catch(() => ({}));
  }

  // --- drain (async fs only - no sync reads) -------------------------------
  async function drainInbox() {
    if (isDisabled()) return;
    const inbox = inboxPath();
    const offsetFile = `${inbox}.offset`;

    let size;
    try {
      const stat = await fs.stat(inbox);
      size = stat.size;
    } catch {
      // ENOENT (or any stat failure) => inert.
      return;
    }

    let offset;
    try {
      const raw = await fs.readFile(offsetFile, "utf8");
      const parsed = Number.parseInt(raw, 10);
      offset = Number.isFinite(parsed) && parsed >= 0 ? parsed : cachedOffset;
    } catch {
      offset = cachedOffset;
    }

    // Truncation guard: file shrank => start over.
    if (size < offset) offset = 0;
    if (size === offset) return;

    let buf;
    try {
      buf = await fs.readFile(inbox);
    } catch (error) {
      log(`read failed: ${error instanceof Error ? error.message : String(error)}`);
      return;
    }

    const slice = buf.subarray(offset);
    const lastNewline = slice.lastIndexOf(0x0a); // "\n"
    if (lastNewline === -1) return; // no complete line yet

    const lines = slice.subarray(0, lastNewline).toString("utf8").split("\n");
    let ack = offset;

    for (const line of lines) {
      const lineEnd = ack + Buffer.byteLength(line, "utf8") + 1; // + newline
      const trimmed = line.trim();
      if (trimmed === "") {
        ack = lineEnd;
        continue;
      }

      let entry;
      try {
        entry = JSON.parse(trimmed);
      } catch (error) {
        log(`skipping malformed line: ${error instanceof Error ? error.message : String(error)}`);
        ack = lineEnd;
        continue;
      }

      const text =
        typeof entry?.text === "string" && entry.text.length > 0 ? entry.text : "";
      if (!text) {
        log("skipping line without non-empty text");
        ack = lineEnd;
        continue;
      }

      const target = String(entry.session || entry.target || activeSessionID || "");
      if (!target) {
        // No resolvable target: do NOT ack past this line; leave it (and the
        // rest) for a later drain.
        break;
      }

      try {
        await deliverSteer(ctx, target, text);
        log(`steered ${target} (${text.length} chars)`);
      } catch (error) {
        // At-most-once: log and ack anyway to avoid a retry storm.
        log(`delivery to ${target} failed: ${error instanceof Error ? error.message : String(error)}`);
      }
      ack = lineEnd;
    }

    cachedOffset = ack;
    try {
      await fs.writeFile(offsetFile, String(ack), "utf8");
    } catch (error) {
      log(`offset write failed: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // --- non-blocking single-flight scheduling -------------------------------
  function scheduleDrain() {
    if (isDisabled()) return;
    if (draining) {
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
          if (pending) scheduleDrain();
        }, MIN_INTERVAL_MS - elapsed);
        if (retryTimer && typeof retryTimer.unref === "function") retryTimer.unref();
      }
      return;
    }
    dirty = false;
    lastCheck = now;
    draining = true;
    Promise.resolve()
      .then(drainInbox)
      .catch(logError)
      .finally(() => {
        draining = false;
        if (dirty) scheduleDrain();
      });
  }

  function logError(error) {
    log(`drain failed: ${error instanceof Error ? error.message : String(error)}`);
  }

  function trackFromInput(input) {
    const id =
      getString(input?.sessionID) ||
      getString(input?.sessionId) ||
      getString(input?.session_id);
    if (id) activeSessionID = id;
  }

  return {
    event: async ({ event }) => {
      try {
        const id = extractSessionID(event);
        if (id) activeSessionID = id;
        scheduleDrain();
      } catch (error) {
        log(`event hook failed: ${error instanceof Error ? error.message : String(error)}`);
      }
    },
    "chat.message": async (input) => {
      try {
        trackFromInput(input);
        scheduleDrain();
      } catch (error) {
        log(`chat.message hook failed: ${error instanceof Error ? error.message : String(error)}`);
      }
    },
    "tool.execute.after": async (input) => {
      try {
        trackFromInput(input);
        scheduleDrain();
      } catch (error) {
        log(`tool.execute.after hook failed: ${error instanceof Error ? error.message : String(error)}`);
      }
    },
  };
};
