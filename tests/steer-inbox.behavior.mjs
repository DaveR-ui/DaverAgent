// tests/steer-inbox.behavior.mjs
// Dependency-free end-to-end behavioral test for plugins/steer-inbox.js.
// Spins up a fake HTTP server, drives the plugin's event hook, and asserts the
// posted steer requests (including the malformed-line, no-target, routing, and
// server-error paths).
//
// Run: node tests/steer-inbox.behavior.mjs
import { createServer } from "node:http";
import { promises as fs } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import os from "node:os";
import path from "node:path";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const line1 = '{"text":"alpha","session":"ses_A"}';
const line2 = "{not valid json";
const line3 = '{"text":"beta"}';
const line4 = '{"text":"gamma","session":"ses_FAIL"}';

// Byte length of line1 + newline + line2 + newline (line 3 must NOT be acked).
const phaseAOffset = Buffer.byteLength(`${line1}\n${line2}\n`, "utf8");
// After every line is acked the offset reaches the full file size.
const finalOffset = Buffer.byteLength(`${line1}\n${line2}\n${line3}\n${line4}\n`, "utf8");

const posts = [];
let tmpDir = "";
let httpServer = null;
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

async function cleanup() {
  if (cleaned) return;
  cleaned = true;
  try {
    if (httpServer) httpServer.close();
  } catch {
    // ignore
  }
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

async function waitForPosts(count, timeoutMs = 4000) {
  const start = Date.now();
  while (posts.length < count) {
    if (Date.now() - start > timeoutMs) return false;
    await sleep(50);
  }
  return true;
}

async function waitForOffset(expected, timeoutMs = 4000) {
  const start = Date.now();
  for (;;) {
    try {
      const raw = await fs.readFile(`${inboxPath()}.offset`, "utf8");
      if (Number.parseInt(raw, 10) === expected) return true;
    } catch {
      // offset file not written yet
    }
    if (Date.now() - start > timeoutMs) return false;
    await sleep(50);
  }
}

function inboxPath() {
  return process.env.OPENCODE_STEER_INBOX;
}

// Hard overall timeout so a hang can never block the suite.
setTimeout(() => {
  console.error("[FAIL] timeout");
  process.exit(1);
}, 15000);

async function main() {
  tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "steer-inbox-"));
  const inbox = path.join(tmpDir, "steer-inbox.jsonl");
  process.env.OPENCODE_STEER_INBOX = inbox;
  delete process.env.OPENCODE_STEER_INBOX_DISABLE;

  // Fake opencode server: record every POST; 500 for ses_FAIL to exercise the
  // delivery-error path.
  httpServer = createServer((req, res) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
    });
    req.on("end", () => {
      let parsed = body;
      try {
        parsed = JSON.parse(body);
      } catch {
        // keep raw body
      }
      posts.push({ url: req.url, body: parsed });
      if (String(req.url).includes("ses_FAIL")) {
        res.writeHead(500, { "content-type": "application/json" });
        res.end(JSON.stringify({ error: { message: "fail" }, data: null }));
      } else {
        res.writeHead(200, { "content-type": "application/json" });
        res.end(JSON.stringify({ data: { ok: true } }));
      }
    });
  });
  await new Promise((resolve) => httpServer.listen(0, "127.0.0.1", resolve));
  const port = httpServer.address().port;

  const { server } = await import(
    pathToFileURL(path.join(repoRoot, "plugins", "steer-inbox.js")).href
  );
  const hooks = await server({
    serverUrl: `http://127.0.0.1:${port}`,
    client: {},
    directory: repoRoot,
  });

  // --- Phase A: no active session -----------------------------------------
  // line 1 steers to its explicit session; line 2 is malformed (acked); line 3
  // has no resolvable target and must be deferred (not acked).
  await fs.writeFile(inbox, `${line1}\n${line2}\n${line3}\n`, "utf8");
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });

  if (!(await waitForPosts(1))) {
    fail("Phase A: expected 1 POST, got none");
    return;
  }
  if (!(await waitForOffset(phaseAOffset))) {
    fail("Phase A: offset did not advance to the end of line 2");
    return;
  }
  if (posts.length !== 1) {
    fail(`Phase A: expected exactly 1 POST, got ${posts.length}`);
    return;
  }
  if (posts[0].url !== "/api/session/ses_A/prompt") {
    fail(`Phase A: expected /api/session/ses_A/prompt, got ${posts[0].url}`);
    return;
  }
  if (!deepEqual(posts[0].body, { prompt: { text: "alpha" }, delivery: "steer" })) {
    fail(`Phase A: unexpected body ${JSON.stringify(posts[0].body)}`);
    return;
  }

  // --- Phase B: routing fix (message.updated must not clobber the session) --
  await sleep(500);
  await hooks.event({
    event: {
      type: "message.updated",
      properties: { sessionID: "ses_REAL", info: { id: "msg_FAKE", sessionID: "ses_REAL" } },
    },
  });
  if (!(await waitForPosts(2))) {
    fail("Phase B: expected a 2nd POST for the deferred line");
    return;
  }
  if (posts.length !== 2) {
    fail(`Phase B: expected exactly 2 POSTs, got ${posts.length}`);
    return;
  }
  if (posts[1].url !== "/api/session/ses_REAL/prompt") {
    fail(`Phase B: expected /api/session/ses_REAL/prompt, got ${posts[1].url}`);
    return;
  }
  if (!deepEqual(posts[1].body, { prompt: { text: "beta" }, delivery: "steer" })) {
    fail(`Phase B: unexpected body ${JSON.stringify(posts[1].body)}`);
    return;
  }

  // --- Phase C: server error must not crash and the line must be acked ------
  await sleep(500);
  await fs.appendFile(inbox, `${line4}\n`, "utf8");
  await hooks.event({ event: { type: "catalog.updated", properties: {} } });
  if (!(await waitForPosts(3))) {
    fail("Phase C: expected a 3rd POST to the failing session");
    return;
  }
  if (posts.length !== 3) {
    fail(`Phase C: expected exactly 3 POSTs, got ${posts.length}`);
    return;
  }
  if (posts[2].url !== "/api/session/ses_FAIL/prompt") {
    fail(`Phase C: expected /api/session/ses_FAIL/prompt, got ${posts[2].url}`);
    return;
  }
  if (!(await waitForOffset(finalOffset))) {
    fail("Phase C: failing line was not acked (offset did not advance)");
    return;
  }

  await cleanup();
  console.log("[ok] steer-inbox behavioral test passed");
  process.exit(0);
}

main().catch((error) => {
  fail(`unexpected error: ${error instanceof Error ? error.stack : String(error)}`);
});
