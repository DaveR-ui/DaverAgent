// tests/session-export.behavior.mjs
// Dependency-free end-to-end behavioral test for plugins/session-export.js.
// Uses a fake `ctx.client` (no network), drives the plugin's hooks, and asserts
// the published snapshot: sort order, status mapping, atomicity, inert behavior
// when the server is unreachable, and the kill switch.
//
// Run: node tests/session-export.behavior.mjs
import { promises as fs } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import os from "node:os";
import path from "node:path";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

let tmpDir = "";
let target = "";
let cleaned = false;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function deepEqual(a, b) {
  if (a === b) return true;
  if (typeof a !== "object" || typeof b !== "object" || a === null || b === null) return false;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  const keysA = Object.keys(a);
  const keysB = Object.keys(b);
  if (keysA.length !== keysB.length) return false;
  return keysA.every((key) => deepEqual(a[key], b[key]));
}

function expect(condition, message) {
  if (!condition) throw new Error(message);
}

async function cleanup() {
  if (cleaned) return;
  cleaned = true;
  try {
    if (tmpDir) await fs.rm(tmpDir, { recursive: true, force: true });
  } catch {
    // ignore
  }
}

function fail(message) {
  console.error(`[FAIL] ${message}`);
  cleanup().finally(() => process.exit(1));
}

async function readSnapshot() {
  const raw = await fs.readFile(target, "utf8");
  return JSON.parse(raw);
}

async function waitForSnapshot(timeoutMs = 4000) {
  const start = Date.now();
  for (;;) {
    try {
      return await readSnapshot();
    } catch {
      // file not written yet
    }
    if (Date.now() - start > timeoutMs) return null;
    await sleep(50);
  }
}

// Hard overall timeout so a hang can never block the suite.
setTimeout(() => {
  console.error("[FAIL] timeout");
  process.exit(1);
}, 15000);

async function main() {
  tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "session-export-"));
  target = path.join(tmpDir, "sessions.json");
  process.env.OPENCODE_SESSION_EXPORT = target;
  delete process.env.OPENCODE_SESSION_EXPORT_DISABLE;

  // Fake sessions: one per status plus two idle sessions with different
  // `updated` values to exercise the descending tie-break.
  const sessions = [
    { id: "ses_busy", title: "Busy session", time: { created: 10, updated: 100 } },
    { id: "ses_retry", title: "Retry session", time: { created: 20, updated: 50 } },
    { id: "ses_idle_new", title: "Idle new", parentID: null, time: { created: 30, updated: 300 } },
    { id: "ses_idle_old", title: "Idle old", parentID: null, time: { created: 40, updated: 200 } },
  ];
  const statusMap = {
    ses_busy: { type: "busy" },
    ses_retry: { type: "retry" },
    ses_idle_new: { type: "idle" },
    ses_idle_old: { type: "idle" },
  };

  const ctx = {
    client: {
      session: {
        list: async () => ({ data: sessions }),
        status: async () => ({ data: statusMap }),
      },
    },
  };

  const { server } = await import(
    pathToFileURL(path.join(repoRoot, "plugins", "session-export.js")).href
  );
  const hooks = await server(ctx);

  // --- Phase A: publish a fresh snapshot ----------------------------------
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });
  const snapshot = await waitForSnapshot();
  expect(snapshot, "Phase A: snapshot file was not written");

  const ids = snapshot.sessions.map((session) => session.id);
  expect(
    deepEqual(ids, ["ses_busy", "ses_retry", "ses_idle_new", "ses_idle_old"]),
    `Phase A: unexpected order ${JSON.stringify(ids)}`,
  );

  const byId = Object.fromEntries(snapshot.sessions.map((session) => [session.id, session]));
  expect(byId.ses_busy.status === "busy", "Phase A: ses_busy status should be busy");
  expect(byId.ses_retry.status === "retry", "Phase A: ses_retry status should be retry");
  expect(byId.ses_idle_new.status === "idle", "Phase A: ses_idle_new status should be idle");
  expect(byId.ses_idle_old.status === "idle", "Phase A: ses_idle_old status should be idle");

  expect(byId.ses_busy.parentID === null, "Phase A: ses_busy parentID should be null");
  expect(byId.ses_idle_new.parentID === null, "Phase A: ses_idle_new parentID should be null");

  expect(byId.ses_busy.updated === 100, "Phase A: ses_busy updated should be 100");
  expect(byId.ses_retry.updated === 50, "Phase A: ses_retry updated should be 50");
  expect(byId.ses_idle_new.updated === 300, "Phase A: ses_idle_new updated should be 300");
  expect(byId.ses_idle_old.updated === 200, "Phase A: ses_idle_old updated should be 200");

  expect(
    typeof snapshot.updatedAt === "string" && !Number.isNaN(Date.parse(snapshot.updatedAt)),
    `Phase A: updatedAt is not a parseable ISO timestamp (${String(snapshot.updatedAt)})`,
  );

  const rawPhaseA = await fs.readFile(target, "utf8");

  // --- Phase B: atomic write leaves no temp file behind -------------------
  const entries = await fs.readdir(tmpDir);
  expect(
    entries.length === 1 && entries[0] === "sessions.json",
    `Phase B: target dir should contain only sessions.json, saw ${JSON.stringify(entries)}`,
  );
  expect(
    !entries.some((name) => name.endsWith(".tmp")),
    `Phase B: leftover temp file(s) ${JSON.stringify(entries)}`,
  );

  // --- Phase C: unreachable server is inert (previous snapshot untouched) --
  await sleep(500);
  ctx.client.session.list = async () => {
    throw new Error("list unreachable");
  };
  ctx.client.session.status = async () => {
    throw new Error("status unreachable");
  };
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });
  await sleep(600);
  const rawPhaseC = await fs.readFile(target, "utf8");
  expect(
    rawPhaseC === rawPhaseA,
    "Phase C: file changed while the server was unreachable",
  );

  // --- Phase D: kill switch disables all action ---------------------------
  await sleep(500);
  ctx.client.session.list = async () => ({ data: sessions });
  ctx.client.session.status = async () => ({ data: statusMap });
  sessions[0].title = "CHANGED TITLE";
  process.env.OPENCODE_SESSION_EXPORT_DISABLE = "1";
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });
  await sleep(600);
  const rawPhaseD = await fs.readFile(target, "utf8");
  expect(rawPhaseD === rawPhaseA, "Phase D: file changed while the kill switch was set");

  await cleanup();
  console.log("[ok] session-export behavioral test passed");
  process.exit(0);
}

main().catch((error) => {
  fail(`unexpected error: ${error instanceof Error ? error.stack : String(error)}`);
});
