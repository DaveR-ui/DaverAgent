#!/usr/bin/env bun
/**
 * davercode-session-bridge — install verification
 *
 * Validates that the plugin is ready to be loaded by opencode:
 *   1. node_modules is installed (deps declared in package.json are resolved)
 *   2. @opencode-ai/plugin (the runtime SDK) is importable
 *   3. opencode.json at the monorepo root registers the plugin
 *   4. the registered path resolves to a directory with package.json + src/index.ts
 *
 * Exit codes:
 *   0  -> install OK
 *   1  -> one or more checks failed (warnings printed to stderr)
 *
 * Designed to be wired as a `postinstall` script in package.json so that
 * any `bun install` inside this plugin dir immediately surfaces a
 * configuration gap to the developer.
 */
import { existsSync, readFileSync, statSync } from "node:fs"
import { dirname, join, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const RED = "\x1b[31m"
const YELLOW = "\x1b[33m"
const GREEN = "\x1b[32m"
const DIM = "\x1b[2m"
const RESET = "\x1b[0m"

const __dirname = dirname(fileURLToPath(import.meta.url))
const PLUGIN_DIR = resolve(__dirname, "..")
// .opencode/plugins/<name>/scripts -> monorepo root is ../../../
const MONOREPO_ROOT = resolve(PLUGIN_DIR, "..", "..", "..")

const errors: string[] = []
const warnings: string[] = []

function fail(msg: string) {
  errors.push(msg)
  process.stderr.write(`${RED}✗${RESET} ${msg}\n`)
}

function warn(msg: string) {
  warnings.push(msg)
  process.stderr.write(`${YELLOW}!${RESET} ${msg}\n`)
}

function ok(msg: string) {
  process.stderr.write(`${GREEN}✓${RESET} ${msg}\n`)
}

// --- 1. node_modules + @opencode-ai/plugin -----------------------------------
const nodeModules = join(PLUGIN_DIR, "node_modules")
const sdkEntry = join(nodeModules, "@opencode-ai", "plugin", "dist", "index.js")

if (!existsSync(nodeModules)) {
  fail(`node_modules missing at ${nodeModules}`)
  warn(`Run \`bun install\` in ${PLUGIN_DIR} to install dependencies.`)
} else if (!existsSync(sdkEntry)) {
  fail(`@opencode-ai/plugin not installed (expected at ${sdkEntry})`)
  warn(`Run \`bun install\` in ${PLUGIN_DIR} to install dependencies.`)
} else {
  ok("dependencies installed (@opencode-ai/plugin present)")
}

// --- 2. opencode.json registers the plugin -----------------------------------
const opencodeJsonPath = join(MONOREPO_ROOT, "opencode.json")
const EXPECTED_PATH = "./.opencode/plugins/davercode-session-bridge"

if (!existsSync(opencodeJsonPath)) {
  fail(`opencode.json not found at ${opencodeJsonPath}`)
} else {
  let cfg: unknown
  try {
    cfg = JSON.parse(readFileSync(opencodeJsonPath, "utf-8"))
  } catch (err) {
    fail(`opencode.json is not valid JSON: ${err instanceof Error ? err.message : String(err)}`)
    cfg = undefined
  }

  if (cfg && typeof cfg === "object") {
    const plugins = (cfg as { plugin?: unknown }).plugin
    if (!Array.isArray(plugins)) {
      fail(`opencode.json has no \`plugin\` array (plugin would not be loaded by the runtime)`)
      warn(`Add to ${opencodeJsonPath}: { "plugin": ["${EXPECTED_PATH}"] }`)
    } else if (!plugins.includes(EXPECTED_PATH)) {
      fail(`plugin NOT registered in opencode.json (current: ${JSON.stringify(plugins)})`)
      warn(`Add "${EXPECTED_PATH}" to the \`plugin\` array in ${opencodeJsonPath}.`)
    } else {
      ok(`plugin registered in opencode.json (${EXPECTED_PATH})`)
    }
  }
}

// --- 3. registered path resolves to a usable directory -----------------------
const registeredAbs = resolve(MONOREPO_ROOT, EXPECTED_PATH)
if (existsSync(registeredAbs)) {
  const stat = statSync(registeredAbs)
  if (!stat.isDirectory()) {
    fail(`registered path ${registeredAbs} exists but is not a directory`)
  } else {
    const pkg = join(registeredAbs, "package.json")
    const idx = join(registeredAbs, "src", "index.ts")
    if (!existsSync(pkg)) warn(`registered dir ${registeredAbs} has no package.json`)
    if (!existsSync(idx)) warn(`registered dir ${registeredAbs} has no src/index.ts`)
    if (existsSync(pkg) && existsSync(idx)) ok("plugin target directory is well-formed")
  }
} else {
  fail(`registered path ${registeredAbs} does not exist on disk`)
}

// --- Summary -----------------------------------------------------------------
process.stderr.write("\n")
if (errors.length > 0) {
  process.stderr.write(
    `${RED}davercode-session-bridge: install FAILED${RESET} (${errors.length} error(s), ${warnings.length} warning(s))\n\n` +
      `${DIM}See BOOTSTRAP.md in this directory for the full install guide.${RESET}\n`,
  )
  process.exit(1)
}

if (warnings.length > 0) {
  process.stderr.write(
    `${YELLOW}davercode-session-bridge: install OK with warnings${RESET} (${warnings.length} warning(s))\n` +
      `${DIM}Plugin will load but may not behave as expected. See warnings above.${RESET}\n`,
  )
  process.exit(0)
}

process.stderr.write(`${GREEN}davercode-session-bridge: install OK${RESET}\n`)
process.exit(0)
