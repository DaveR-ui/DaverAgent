#!/usr/bin/env bash
# extract-keywords.sh - deterministic keyword pre-processor (Step 0a of the prompt pipeline).
#
# Reads a raw human prompt (stdin, or argv as fallback), extracts candidate terms,
# greps them against docs/project.md and docs/context/README.md, and emits a JSON
# "keyword packet" on stdout for the interpreter subagent (Step 0).
#
# Contract:
#   - ALWAYS exits 0. Empty matches are valid output. This script never fails the pipeline.
#   - Output is a single JSON object on stdout.
#   - Pure bash + grep/sed/awk/tr. No jq, python, or node dependency.

set -u
export LC_ALL=C

MAX_MATCHES_PER_TERM=8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." 2>/dev/null && pwd)"
PROJECT_MD="${REPO_ROOT}/docs/project.md"
CONTEXT_README="${REPO_ROOT}/docs/context/README.md"

# --- input: argv wins, otherwise stdin ---------------------------------------
if [ $# -gt 0 ]; then
  RAW_PROMPT="$*"
else
  RAW_PROMPT="$(cat 2>/dev/null)"
fi

# Strip CR so PowerShell-piped input and CRLF sources stay clean.
RAW_PROMPT="${RAW_PROMPT//$'\r'/}"

# --- helpers ------------------------------------------------------------------
json_escape() {
  # Escape the characters that must not appear raw inside a JSON string.
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  printf '%s' "${s}"
}

# --- term extraction -----------------------------------------------------------
# lowercase -> keep [a-z0-9], turn everything else into separators -> one term per
# line -> length >= 3 -> dedupe preserving first-seen order.
TERMS="$(printf '%s' "${RAW_PROMPT}" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9][^a-z0-9]*/ /g' \
  | tr -s ' ' '\n' \
  | awk 'length($0) >= 3 && !seen[$0]++')"

# --- slices table section of docs/project.md (for candidate slice names) -------
SLICES_SECTION=""
if [ -f "${PROJECT_MD}" ]; then
  SLICES_SECTION="$(awk '/^## .*Slices Table/{f=1; next} /^## /{if (f) exit} f' "${PROJECT_MD}" 2>/dev/null)"
fi

# --- emit JSON ------------------------------------------------------------------
printf '{\n'
printf '  "raw_prompt": "%s",\n' "$(json_escape "${RAW_PROMPT}")"

# extracted_terms
printf '  "extracted_terms": ['
first=1
while IFS= read -r term; do
  [ -z "${term}" ] && continue
  [ ${first} -eq 0 ] && printf ', '
  first=0
  printf '"%s"' "$(json_escape "${term}")"
done < <(printf '%s\n' "${TERMS}")
printf '],\n'

# matches: term -> ["path:line: matching line", ...] (case-insensitive substring grep)
printf '  "matches": {'
first=1
while IFS= read -r term; do
  [ -z "${term}" ] && continue
  [ ${first} -eq 0 ] && printf ','
  first=0
  printf '\n    "%s": [' "$(json_escape "${term}")"
  term_hits=""
  for doc in "${PROJECT_MD}" "${CONTEXT_README}"; do
    [ -f "${doc}" ] || continue
    rel="${doc#"${REPO_ROOT}"/}"
    hits="$(grep -in -F -m "${MAX_MATCHES_PER_TERM}" -- "${term}" "${doc}" 2>/dev/null | tr -d '\r' | sed "s|^|${rel}:|" || true)"
    [ -n "${hits}" ] && term_hits="${term_hits}${hits}"$'\n'
  done
  mfirst=1
  while IFS= read -r line; do
    [ -z "${line}" ] && continue
    [ ${mfirst} -eq 0 ] && printf ', '
    mfirst=0
    printf '"%s"' "$(json_escape "${line}")"
  done < <(printf '%s\n' "${term_hits}" | head -n "${MAX_MATCHES_PER_TERM}")
  printf ']'
done < <(printf '%s\n' "${TERMS}")
printf '\n  },\n'

# candidates: slice ids whose Slices-table row mentions any extracted term
printf '  "candidates": ['
candidates=""
if [ -n "${SLICES_SECTION}" ]; then
  while IFS= read -r term; do
    [ -z "${term}" ] && continue
    ids="$(printf '%s\n' "${SLICES_SECTION}" \
      | grep -i -F -- "${term}" 2>/dev/null \
      | cut -d'|' -f2 \
      | grep -o '`[^`][^`]*`' 2>/dev/null \
      | tr -d '`' || true)"
    [ -n "${ids}" ] && candidates="${candidates}${ids}"$'\n'
  done < <(printf '%s\n' "${TERMS}")
fi
cfirst=1
while IFS= read -r cand; do
  [ -z "${cand}" ] && continue
  [ ${cfirst} -eq 0 ] && printf ', '
  cfirst=0
  printf '"%s"' "$(json_escape "${cand}")"
done < <(printf '%s\n' "${candidates}" | awk 'NF && !seen[$0]++')
printf ']\n'
printf '}\n'

exit 0
