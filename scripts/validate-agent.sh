#!/usr/bin/env bash
# validate-agent.sh - static integrity check for the global opencode agent tree.
#
# This repository IS the global opencode config (installed at ~/.config/opencode),
# so the layout is flat: agents/ at the root, no per-project .opencode/ prefix.
#
# Verifies the agent configuration the way a linter would, so broken installs
# fail loudly instead of silently degrading the system:
#
#   1.  opencode.json is valid JSON
#   2.  flat agents/ layout (no legacy agents/subagents/); no agent uses the
#       deprecated `tools:` frontmatter field (use `permission:`); `model:` is
#       optional (omission inherits the invoking primary agent's model)
#   3.  opencode.json declares no field the installed runtime ignores: the
#       unsupported top-level keys (logLevel, server, subagent_depth, layout),
#       the unsupported experimental keys (disable_paste_summary, batch_tool,
#       openTelemetry, primary_tools, continue_loop_on_deny), and the
#       unsupported compaction keys (prune, tail_turns)
#   4.  every output_schema frontmatter path resolves to an existing schema file
#   5.  every permission.task allow target in any agent maps to a real agent
#       (scalar `task: allow|ask|deny` is valid and has no targets; wildcard
#       targets are skipped; a file with no permission.task is fine)
#   6.  required frontmatter (description, mode) on every agent file
#   7.  config instructions/references paths resolve (docs/ paths are warnings -
#       they live in the target project; the `agent-system` reference resolves here)
#   8.  every *.schema.json parses as valid JSON
#   9.  every agents/*.schema.json is structurally closed: draft 2020-12, root
#       additionalProperties:false with a non-empty required array, and a
#       description on every property (recursively, through properties/items)
#   10. every re_route_to enum value resolves to agents/<value>.md; a
#       re_route_language enum only allows angular|go
#
# Exit code: 0 = OK (warnings allowed), 1 = errors found.
# Pure bash + python3 (no jq/node required).

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." 2>/dev/null && pwd)"

AGENTS_DIR="${ROOT}/agents"

if [ -f "${ROOT}/opencode.json" ]; then
  CONFIG="${ROOT}/opencode.json"
else
  echo "ERROR: no opencode.json found at ${ROOT}" >&2
  exit 1
fi

ERRORS=0
WARNINGS=0

err()  { echo "ERROR: $*" >&2;  ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN:  $*" >&2;  WARNINGS=$((WARNINGS + 1)); }

# --- helpers -----------------------------------------------------------------

have_python() { command -v python3 >/dev/null 2>&1; }

resolve() {
  # Resolve a path relative to the config root (no .opencode/ prefix anymore).
  local p="$1"
  if [ -e "${ROOT}/${p}" ]; then echo "${ROOT}/${p}"; return 0; fi
  return 1
}

frontmatter() {
  # Print the frontmatter block (between the first two --- lines) of a file.
  # Strip a leading UTF-8 BOM if present (breaks the ^--- anchor otherwise).
  sed '1s/^\xEF\xBB\xBF//' "$1" | awk 'NR==1 && /^---/{f=1; next} f && /^---/{exit} f'
}

# --- 1. config JSON validity -------------------------------------------------

echo "== [1/10] config JSON =="
if ! have_python; then
  warn "python3 not found; skipping JSON validation of ${CONFIG}"
else
  if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "${CONFIG}"; then
    err "${CONFIG} is not valid JSON"
  else
    echo "ok: ${CONFIG}"
  fi
fi

# --- 2. flat agent layout + frontmatter cross-check --------------------------
# NOTE: model/temperature live in the agent frontmatter, not in opencode.json's
# (nonexistent) agent block. `model:` is an OPTIONAL per-agent override —
# omission means the subagent inherits the invoking primary agent's model.
# The only hard frontmatter error here is the deprecated `tools:` field.

echo "== [2/10] flat agents/ layout + frontmatter (model optional; tools: check) =="
if [ -d "${ROOT}/agents/subagents" ]; then
  err "legacy agents/subagents/ layout found; agents must be flat under agents/"
fi
if [ ! -d "${AGENTS_DIR}" ]; then
  err "agents directory not found: ${AGENTS_DIR}"
else
  AGENT_FILES="$(find "${AGENTS_DIR}" -maxdepth 1 -name '*.md' | sort)"
  if [ -z "${AGENT_FILES}" ]; then
    err "no *.md agent files found in ${AGENTS_DIR}"
  fi
  while IFS= read -r md; do
    name="$(basename "${md}")"
    fm="$(frontmatter "${md}")"
    if echo "${fm}" | grep -q '^tools:'; then
      err "${name} uses deprecated 'tools:' frontmatter; use 'permission:' with allow/deny/ask instead"
    fi
  done <<< "${AGENT_FILES}"
  echo "ok: flat layout; frontmatter scanned (model optional; tools: check)"
fi

# --- 3. unsupported config fields --------------------------------------------
# SCHEMA-ONLY CHECK. The lists below mirror the installed runtime's config
# normalizer (core/src/config/normalize.ts, verified on v2.0.8):
#   unsupportedTopLevel      = logLevel, server, subagent_depth, layout
#   unsupportedExperimental  = disable_paste_summary, batch_tool, openTelemetry,
#                              primary_tools, continue_loop_on_deny
#   unsupported compaction   = prune, tail_turns
# These fields are accepted but IGNORED by V2 (some are reported only as an
# internal "unsupported" diagnostic, not a hard error). Re-verify against the
# runtime source if the opencode major version changes.

echo "== [3/10] unsupported config fields =="
if ! have_python; then
  warn "python3 not found; skipping unsupported-config-field check"
else
  PY_OUT="$(python3 - "${CONFIG}" <<'PY'
import json, sys

try:
    cfg = json.load(open(sys.argv[1]))
except (json.JSONDecodeError, OSError):
    # Check [1] reports the malformed config; emit nothing so this check
    # cannot claim "ok" for a file it could not read.
    sys.exit(0)

# Keep in sync with core/src/config/normalize.ts (installed runtime v2.0.8).
unsupported_top = ["logLevel", "server", "subagent_depth", "layout"]
unsupported_experimental = [
    "disable_paste_summary",
    "batch_tool",
    "openTelemetry",
    "primary_tools",
    "continue_loop_on_deny",
]
unsupported_compaction = ["prune", "tail_turns"]

if not isinstance(cfg, dict):
    sys.exit(0)

for key in unsupported_top:
    if key in cfg:
        print(f"ERROR: opencode.json has unsupported top-level field '{key}' "
              f"(ignored by V2)")

experimental = cfg.get("experimental")
if isinstance(experimental, dict):
    for key in unsupported_experimental:
        if key in experimental:
            print(f"ERROR: opencode.json has unsupported field "
                  f"'experimental.{key}' (ignored by V2)")

compaction = cfg.get("compaction")
if isinstance(compaction, dict):
    for key in unsupported_compaction:
        if key in compaction:
            print(f"ERROR: opencode.json has unsupported field "
                  f"'compaction.{key}' (ignored by V2)")
PY
)"
  if [ -z "${PY_OUT}" ]; then
    echo "ok: no unsupported config fields"
  else
    while IFS= read -r line; do
      case "${line}" in
        ERROR:*) err "${line#ERROR: }" ;;
        WARN:*)  warn "${line#WARN: }" ;;
        *)       [ -n "${line}" ] && echo "${line}" ;;
      esac
    done <<< "${PY_OUT}"
  fi
fi

# --- 4. output_schema resolution ---------------------------------------------

echo "== [4/10] output_schema files =="
for md in "${AGENTS_DIR}"/*.md; do
  [ -f "${md}" ] || continue
  schema="$(frontmatter "${md}" | awk -F': *' '/^output_schema:/{gsub(/ /,"",$2); print $2; exit}')"
  if [ -n "${schema}" ]; then
    base="$(cd "$(dirname "${md}")" && pwd)"
    if [ ! -e "${base}/${schema}" ]; then
      err "$(basename "${md}") declares output_schema '${schema}' but the file does not exist"
    else
      echo "ok: $(basename "${md}") -> ${schema}"
    fi
  fi
done

# --- 4. permission.task entries ---------------------------------------------

echo "== [5/10] permission.task targets =="
for md in "${AGENTS_DIR}"/*.md; do
  [ -f "${md}" ] || continue
  name="$(basename "${md}")"
  # Accept both forms: scalar `task: allow|ask|deny` (no targets) and the map
  # form `task:` followed by indented `<agent>: <action>` entries.
  targets="$(frontmatter "${md}" | awk '
    /^permission:/{p=1; next}
    p && /^[^ ]/{p=0}
    p && /^  task:/{t=1; rest=$0; sub(/^  task:[ ]*/,"",rest); if (rest!=""){t=0}; next}
    t && /^    [^ ]/{print $1; next}
    t && /^  [^ ]/{t=0}
  ' | awk '{sub(/:.*/,""); print}')"
  for id in ${targets}; do
    case "${id}" in
      *'*'*|*'?'*|*'['*) continue ;;   # wildcard pattern: nothing to resolve
    esac
    if [ ! -f "${AGENTS_DIR}/${id}.md" ]; then
      err "${name} grants task access to '${id}' but agents/${id}.md does not exist"
    fi
  done
  if [ -n "${targets}" ]; then echo "ok: ${name} task targets exist"; fi
done

# --- 5. required frontmatter -------------------------------------------------

echo "== [6/10] required frontmatter =="
for md in "${AGENTS_DIR}"/*.md; do
  [ -f "${md}" ] || continue
  name="$(basename "${md}")"
  fm="$(frontmatter "${md}")"
  if ! echo "${fm}" | grep -q '^description:'; then
    err "${name} is missing 'description' in frontmatter"
  fi
  mode="$(echo "${fm}" | awk -F': *' '/^mode:/{print $2; exit}')"
  if [ -z "${mode}" ]; then
    err "${name} is missing 'mode' in frontmatter"
  fi
  if [ "${name}" = "delivery.md" ]; then
    if [ -n "${mode}" ] && [ "${mode}" != "primary" ]; then err "${name} must be mode: primary"; fi
  else
    if [ -n "${mode}" ] && [ "${mode}" != "subagent" ]; then err "${name} must be mode: subagent"; fi
  fi
done
echo "ok: frontmatter scanned"

# --- 6. instructions / references paths --------------------------------------

echo "== [7/10] config instructions/references paths =="
if have_python; then
  PY_OUT="$(python3 - "${CONFIG}" "${ROOT}" <<'PY'
import json, os, sys
cfg = json.load(open(sys.argv[1]))
root = sys.argv[2]

def resolve(p):
    cands = [os.path.join(root, p)]
    for c in cands:
        if os.path.exists(c):
            return c
    return None

for p in cfg.get("instructions", []):
    r = resolve(p)
    if r is None:
        is_docs = p.startswith("docs/")
        tag = "WARN" if is_docs else "ERROR"
        print(f"{tag}: instruction path '{p}' does not exist (docs/ = target project)")
    else:
        print(f"ok: instruction '{p}'")

for name, ref in cfg.get("references", {}).items():
    r = resolve(ref.get("path", ""))
    if r is None:
        is_docs = ref.get("path", "").startswith("docs/")
        tag = "WARN" if is_docs else "ERROR"
        print(f"{tag}: reference '{name}' path '{ref.get('path')}' does not exist")
    else:
        print(f"ok: reference '{name}'")
PY
)"
  while IFS= read -r line; do
    case "${line}" in
      ERROR:*) err "${line#ERROR: }" ;;
      WARN:*)  warn "${line#WARN: }" ;;
      *)       echo "${line}" ;;
    esac
  done <<< "${PY_OUT}"
fi

# --- 7. schema JSON files ----------------------------------------------------

echo "== [8/10] schema JSON files =="
if ! have_python; then
  warn "python3 not found; skipping schema JSON validation"
else
  for f in "${AGENTS_DIR}"/*.schema.json "${SCRIPT_DIR}"/*.schema.json; do
    # `[ -f ]` also skips an unmatched glob literal (e.g. no scripts/*.schema.json).
    [ -f "${f}" ] || continue
    if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "${f}" 2>/dev/null; then
      err "invalid JSON schema: ${f}"
    else
      echo "ok: $(basename "${f}")"
    fi
  done
fi

# --- 8. schema structural closure --------------------------------------------

echo "== [9/10] schema structural closure =="
if ! have_python; then
  warn "python3 not found; skipping schema structural closure check"
else
  PY_OUT="$(python3 - "${AGENTS_DIR}" "${ROOT}" <<'PY'
import glob, json, os, sys
agents_dir = sys.argv[1]
root = sys.argv[2]

files = sorted(glob.glob(os.path.join(agents_dir, "*.schema.json")))
if not files:
    print("WARN: no agents/*.schema.json files found")

def walk(node, ptr, rel, errors):
    if not isinstance(node, dict):
        return
    if node.get("type") == "object" or "properties" in node:
        if node.get("additionalProperties") is not False:
            errors.append(f"{rel}#{ptr} is missing 'additionalProperties': false")
        required = node.get("required")
        if not isinstance(required, list) or not required:
            errors.append(f"{rel}#{ptr} is missing a non-empty 'required' array")
        for name, sub in node.get("properties", {}).items():
            pptr = f"{ptr}/properties/{name}"
            if not isinstance(sub, dict):
                continue
            desc = sub.get("description")
            if not isinstance(desc, str) or not desc.strip():
                errors.append(f"{rel}#{pptr} is missing 'description'")
            walk(sub, pptr, rel, errors)
    items = node.get("items")
    if isinstance(items, dict):
        walk(items, f"{ptr}/items", rel, errors)

for f in files:
    rel = os.path.relpath(f, root)
    try:
        schema = json.load(open(f))
    except json.JSONDecodeError:
        continue  # check 7 already reports malformed JSON
    errors = []
    uri = schema.get("$schema")
    if not isinstance(uri, str) or "2020-12" not in uri:
        errors.append(f"{rel} is missing a '$schema' containing '2020-12'")
    walk(schema, "", rel, errors)
    if errors:
        for e in errors:
            print(f"ERROR: {e}")
    else:
        print(f"ok: {rel}")
PY
)"
  while IFS= read -r line; do
    case "${line}" in
      ERROR:*) err "${line#ERROR: }" ;;
      WARN:*)  warn "${line#WARN: }" ;;
      *)       echo "${line}" ;;
    esac
  done <<< "${PY_OUT}"
fi

# --- 9. schema enum agent targets resolve ------------------------------------

echo "== [10/10] schema enum agent targets resolve =="
if ! have_python; then
  warn "python3 not found; skipping schema enum agent target check"
else
  PY_OUT="$(python3 - "${AGENTS_DIR}" "${ROOT}" <<'PY'
import glob, json, os, sys
agents_dir = sys.argv[1]
root = sys.argv[2]

files = sorted(glob.glob(os.path.join(agents_dir, "*.schema.json")))

def collect(node, found):
    if not isinstance(node, dict):
        return
    for key, sub in node.get("properties", {}).items():
        if isinstance(sub, dict):
            if key in ("re_route_to", "re_route_language") and isinstance(sub.get("enum"), list):
                found.append((key, sub["enum"]))
            collect(sub, found)
    items = node.get("items")
    if isinstance(items, dict):
        collect(items, found)

for f in files:
    rel = os.path.relpath(f, root)
    try:
        schema = json.load(open(f))
    except json.JSONDecodeError:
        continue  # check 7 already reports malformed JSON
    found = []
    collect(schema, found)
    errors = []
    has_re_route_to = False
    for key, values in found:
        if key == "re_route_to":
            has_re_route_to = True
            for v in values:
                if not os.path.isfile(os.path.join(agents_dir, f"{v}.md")):
                    errors.append(f"{rel} re_route_to enum value '{v}' has no agents/{v}.md")
        else:  # re_route_language
            for v in values:
                if v not in ("angular", "go"):
                    errors.append(
                        f"{rel} re_route_language enum value '{v}' is not one of angular|go"
                    )
    if errors:
        for e in errors:
            print(f"ERROR: {e}")
    elif has_re_route_to:
        print(f"ok: {rel} re_route_to targets resolve")
    else:
        print(f"ok: {rel} (no re_route_to enum)")
PY
)"
  while IFS= read -r line; do
    case "${line}" in
      ERROR:*) err "${line#ERROR: }" ;;
      WARN:*)  warn "${line#WARN: }" ;;
      *)       echo "${line}" ;;
    esac
  done <<< "${PY_OUT}"
fi

# --- summary -----------------------------------------------------------------

echo ""
if [ "${ERRORS}" -gt 0 ]; then
  echo "FAIL: ${ERRORS} error(s), ${WARNINGS} warning(s)" >&2
  exit 1
fi
echo "PASS: 0 errors, ${WARNINGS} warning(s)"
exit 0
