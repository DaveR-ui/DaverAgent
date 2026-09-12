#!/usr/bin/env bash
# validate-agent.sh - static integrity check for the global opencode agent tree.
#
# This repository IS the global opencode config (installed at ~/.config/opencode),
# so the layout is flat: agents/ at the root, no per-project .opencode/ prefix.
#
# Verifies the agent configuration the way a linter would, so broken installs
# fail loudly instead of silently degrading the system:
#
#   1. opencode.json is valid JSON
#   2. flat agents/ layout (no legacy agents/subagents/); no agent uses the
#      deprecated `tools:` frontmatter field (use `permission:`); `model:` is
#      optional (omission inherits the invoking primary agent's model)
#   3. every output_schema frontmatter path resolves to an existing schema file
#   4. every permission.task entry in delivery/orchestrator maps to a real agent
#   5. required frontmatter (description, mode) on every agent file
#   6. config instructions/references paths resolve (docs/ paths are warnings -
#      they live in the target project; the `agent-system` reference resolves here)
#   7. every *.schema.json parses as valid JSON
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

echo "== [1/7] config JSON =="
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

echo "== [2/7] flat agents/ layout + frontmatter (model optional; tools: check) =="
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

# --- 3. output_schema resolution ---------------------------------------------

echo "== [3/7] output_schema files =="
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

echo "== [4/7] permission.task targets =="
for md in "${AGENTS_DIR}"/delivery.md "${AGENTS_DIR}"/orchestrator.md; do
  [ -f "${md}" ] || continue
  targets="$(frontmatter "${md}" | awk '/^  task:/{f=1; next} /^[^ ]/{f=0} f && /^    [a-z0-9-]+: allow/{line=$1; sub(/:.*/,"",line); print line}')"
  for id in ${targets}; do
    if [ ! -f "${AGENTS_DIR}/${id}.md" ]; then
      err "$(basename "${md}") grants task access to '${id}' but agents/${id}.md does not exist"
    fi
  done
  if [ -n "${targets}" ]; then echo "ok: $(basename "${md}") task targets exist"; fi
done

# --- 5. required frontmatter -------------------------------------------------

echo "== [5/7] required frontmatter =="
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

echo "== [6/7] config instructions/references paths =="
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

echo "== [7/7] schema JSON files =="
for f in "${AGENTS_DIR}"/*.schema.json "${SCRIPT_DIR}"/*.schema.json; do
  [ -f "${f}" ] || continue
  if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "${f}" 2>/dev/null; then
    err "invalid JSON schema: ${f}"
  else
    echo "ok: $(basename "${f}")"
  fi
done

# --- summary -----------------------------------------------------------------

echo ""
if [ "${ERRORS}" -gt 0 ]; then
  echo "FAIL: ${ERRORS} error(s), ${WARNINGS} warning(s)" >&2
  exit 1
fi
echo "PASS: 0 errors, ${WARNINGS} warning(s)"
exit 0
