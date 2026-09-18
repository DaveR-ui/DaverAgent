// tests/session-export.behavior.mjs
// Dependency-free end-to-end behavioral test for plugins/session-export.js.
// Uses a fake `ctx.client` (no network), drives the plugin's hooks, and asserts
// the published snapshot: sort order (including the id-ascending tie-break),
// status mapping, atomicity, inert behavior when the server is unreachable,
// the status-optional / unknown-status fallback, the kill switch, and
// failed-write temp cleanup.
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

async function waitForSnapshotWhere(predicate, timeoutMs = 4000) {
  const start = Date.now();
  for (;;) {
    try {
      const snapshot = await readSnapshot();
      if (predicate(snapshot)) return snapshot;
    } catch {
      // file not written yet / unreadable
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

  // Fake sessions: one per status, an idle child with a parent, two idle
  // sessions with the same `updated` to exercise the id-ascending tie-break,
  // and one session absent from the status map (must become "unknown" and sort
  // last despite having the highest `updated`).
  const sessions = [
    { id: "ses_busy", title: "Busy session", time: { created: 10, updated: 100 } },
    { id: "ses_retry", title: "Retry session", time: { created: 20, updated: 50 } },
    {
      id: "ses_child",
      title: "Child session",
      parentID: "ses_parent",
      time: { created: 30, updated: 400 },
    },
    { id: "ses_idle_old", title: "Idle old", parentID: null, time: { created: 40, updated: 300 } },
    { id: "ses_tie_a", title: "Tie A", parentID: null, time: { created: 50, updated: 200 } },
    { id: "ses_tie_b", title: "Tie B", parentID: null, time: { created: 60, updated: 200 } },
    { id: "ses_unknown", title: "Unknown", parentID: null, time: { created: 70, updated: 999 } },
  ];
  const statusMap = {
    ses_busy: { type: "busy" },
    ses_retry: { type: "retry" },
    ses_child: { type: "idle" },
    ses_idle_old: { type: "idle" },
    ses_tie_a: { type: "idle" },
    ses_tie_b: { type: "idle" },
    // ses_unknown is intentionally absent from the status map.
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

  // --- Phase A: publish a fresh snapshot (list + status both succeed) ------
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });
  const snapshot = await waitForSnapshot();
  expect(snapshot, "Phase A: snapshot file was not written");

  const ids = snapshot.sessions.map((session) => session.id);
  const expectedOrder = [
    "ses_busy",
    "ses_retry",
    "ses_child",
    "ses_idle_old",
    "ses_tie_a",
    "ses_tie_b",
    "ses_unknown",
  ];
  expect(
    deepEqual(ids, expectedOrder),
    `Phase A: unexpected order ${JSON.stringify(ids)}`,
  );

  const byId = Object.fromEntries(snapshot.sessions.map((session) => [session.id, session]));
  const expectedStatuses = {
    ses_busy: "busy",
    ses_retry: "retry",
    ses_child: "idle",
    ses_idle_old: "idle",
    ses_tie_a: "idle",
    ses_tie_b: "idle",
    ses_unknown: "unknown",
  };
  for (const [id, status] of Object.entries(expectedStatuses)) {
    expect(
      byId[id].status === status,
      `Phase A: ${id} status should be ${status} (got ${byId[id].status})`,
    );
  }

  expect(
    byId.ses_child.parentID === "ses_parent",
    "Phase A: ses_child parentID should round-trip as ses_parent",
  );
  expect(byId.ses_busy.parentID === null, "Phase A: ses_busy parentID should be null");
  expect(byId.ses_unknown.status === "unknown", "Phase A: ses_unknown should be unknown");

  expect(byId.ses_busy.updated === 100, "Phase A: ses_busy updated should be 100");
  expect(byId.ses_retry.updated === 50, "Phase A: ses_retry updated should be 50");
  expect(byId.ses_child.updated === 400, "Phase A: ses_child updated should be 400");
  expect(byId.ses_idle_old.updated === 300, "Phase A: ses_idle_old updated should be 300");
  expect(byId.ses_unknown.updated === 999, "Phase A: ses_unknown updated should be 999");

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

  // --- Phase C: list ok, status fails -> rewrite with all "unknown" -------
  await sleep(500);
  sessions[0].title = "Busy session (C)";
  ctx.client.session.list = async () => ({ data: sessions });
  ctx.client.session.status = async () => {
    throw new Error("status unreachable");
  };
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });
  const phaseC = await waitForSnapshotWhere(
    (value) =>
      value.sessions.length === 7 &&
      value.sessions.every((session) => session.status === "unknown"),
  );
  expect(phaseC, "Phase C: snapshot with all-unknown statuses was not written");
  expect(
    phaseC.sessions.every((session) => session.status === "unknown"),
    "Phase C: every session should have status unknown when status() fails",
  );
  const phaseCBusy = phaseC.sessions.find((session) => session.id === "ses_busy");
  expect(
    phaseCBusy?.title === "Busy session (C)",
    "Phase C: rewritten snapshot should reflect the changed list title",
  );
  const rawPhaseC = await fs.readFile(target, "utf8");
  expect(rawPhaseC !== rawPhaseA, "Phase C: file should be rewritten when status() fails");

  // --- Phase D: list fails -> previous snapshot left untouched (inert) ----
  await sleep(500);
  ctx.client.session.list = async () => {
    throw new Error("list unreachable");
  };
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });
  await sleep(600);
  const rawPhaseD = await fs.readFile(target, "utf8");
  expect(
    rawPhaseD === rawPhaseC,
    "Phase D: file changed while session.list was unreachable",
  );

  // --- Phase E: kill switch disables all action ---------------------------
  await sleep(500);
  ctx.client.session.list = async () => ({ data: sessions });
  ctx.client.session.status = async () => ({ data: statusMap });
  sessions[0].title = "CHANGED TITLE E";
  process.env.OPENCODE_SESSION_EXPORT_DISABLE = "1";
  try {
    await hooks.event({ event: { type: "catalog.updated", properties: {} } });
    await sleep(600);
    const rawPhaseE = await fs.readFile(target, "utf8");
    expect(rawPhaseE === rawPhaseC, "Phase E: file changed while the kill switch was set");
  } finally {
    delete process.env.OPENCODE_SESSION_EXPORT_DISABLE;
  }

  // --- Phase F: failed write removes the temp file ------------------------
  await sleep(500);
  const failDir = path.join(tmpDir, "failwrite");
  await fs.mkdir(failDir, { recursive: true });
  const existingDir = path.join(failDir, "targetdir");
  await fs.mkdir(existingDir, { recursive: true });
  process.env.OPENCODE_SESSION_EXPORT = existingDir;
  sessions[0].title = "CHANGED TITLE F";
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });
  await sleep(600);
  const failEntries = await fs.readdir(failDir);
  expect(
    !failEntries.some((name) => name.endsWith(".tmp")),
    `Phase F: leftover temp file(s) after a failed write ${JSON.stringify(failEntries)}`,
  );

  await cleanup();
  console.log("[ok] session-export behavioral test passed");
  process.exit(0);
}

main().catch((error) => {
  fail(`unexpected error: ${error instanceof Error ? error.stack : String(error)}`);
});
