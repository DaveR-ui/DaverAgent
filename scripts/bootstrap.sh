#!/usr/bin/env bash
# bootstrap.sh - install or update the DaverAgent global opencode config.
#
# The repository root IS the opencode config directory. This script clones the
# repo into the target (default ~/.config/opencode) and keeps it updated. It is
# idempotent: re-running it updates an existing clone instead of re-cloning.
#
# Usage:
#   bash scripts/bootstrap.sh [options]
#
# Options:
#   --verify-only     Report what would happen; write nothing.
#   --target DIR      Install destination
#                     (default: ${XDG_CONFIG_HOME:-$HOME/.config}/opencode).
#   --repo-url URL    Git remote to clone
#                     (default: https://github.com/DaveR-ui/DaverAgent.git).
#   --branch NAME     Branch to check out / track (default: remote default).
#   -h, --help        Show this help.
#
# Exit codes: 0 = success (or verify passed), 1 = failure.

set -u

REPO_URL="${DAVERAGENT_REPO_URL:-https://github.com/DaveR-ui/DaverAgent.git}"
TARGET_DEFAULT="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
TARGET="$TARGET_DEFAULT"
BRANCH=""
VERIFY_ONLY=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log()  { printf '%s\n' "$*"; }
warn() { printf 'WARN:  %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --verify-only) VERIFY_ONLY=1 ;;
    --target)      shift; [ $# -gt 0 ] || die "--target needs a value"; TARGET="$1" ;;
    --repo-url)    shift; [ $# -gt 0 ] || die "--repo-url needs a value"; REPO_URL="$1" ;;
    --branch)      shift; [ $# -gt 0 ] || die "--branch needs a value"; BRANCH="$1" ;;
    -h|--help)     usage; exit 0 ;;
    *)             die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

same_path() {
  [ -e "$1" ] && [ -e "$2" ] || return 1
  [ "$(cd "$1" 2>/dev/null && pwd -P)" = "$(cd "$2" 2>/dev/null && pwd -P)" ]
}

origin_url() {
  git -C "$1" remote get-url origin 2>/dev/null || true
}

normalize_url() {
  # Normalize a git remote to "host/owner/repo" (lowercased) so https, ssh, and
  # scp-like forms compare equal.
  printf '%s' "$1" \
    | sed -E 's#^[A-Za-z][A-Za-z0-9+.-]*://##; s#^[^@/]+@##; s#^([^/:]+):#\1/#; s#\.git$##; s#/+$##' \
    | tr '[:upper:]' '[:lower:]'
}

is_our_install() {
  # True when "$1" is a checkout/clone of this agent-system repo. Prefer the
  # normalized remote match; fall back to a structural marker so an SSH URL or
  # an origin alias is not misclassified as a foreign config (which would back
  # it up and re-clone, discarding local edits).
  local root="$1"
  [ -d "${root}/.git" ] || return 1
  local norm_origin norm_repo
  norm_origin="$(normalize_url "$(origin_url "${root}")")"
  norm_repo="$(normalize_url "${REPO_URL}")"
  if [ -n "${norm_origin}" ] && [ "${norm_origin}" = "${norm_repo}" ]; then
    return 0
  fi
  [ -f "${root}/opencode.json" ] || return 1
  [ -d "${root}/agents" ]        || return 1
  if [ -d "${root}/agents/subagents" ]; then return 1; fi
  grep -q '"agent-system"' "${root}/opencode.json" 2>/dev/null
}

verify_layout() {
  local root="$1" fail=0
  [ -f "${root}/opencode.json" ] || { warn "missing ${root}/opencode.json"; fail=1; }
  [ -d "${root}/agents" ]        || { warn "missing ${root}/agents/"; fail=1; }
  [ -d "${root}/protocols" ]     || { warn "missing ${root}/protocols/"; fail=1; }
  [ -d "${root}/workflows" ]     || { warn "missing ${root}/workflows/"; fail=1; }
  [ -d "${root}/scripts" ]       || { warn "missing ${root}/scripts/"; fail=1; }
  if [ -d "${root}/agents/subagents" ]; then
    warn "legacy ${root}/agents/subagents/ found; the flat layout is expected"
    fail=1
  fi
  if [ -f "${root}/opencode.json" ] && command -v python3 >/dev/null 2>&1; then
    if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "${root}/opencode.json" 2>/dev/null; then
      warn "${root}/opencode.json is not valid JSON"; fail=1
    fi
  fi
  return "${fail}"
}

clone_into() {
  local dest="$1"
  if [ -n "${BRANCH}" ]; then
    git clone --branch "${BRANCH}" "${REPO_URL}" "${dest}"
  else
    git clone "${REPO_URL}" "${dest}"
  fi
}

backup_name() {
  printf '%s.bak.%s' "$1" "$(date +%Y%m%d-%H%M%S)"
}

install_plugin_deps() {
  # Plugin dependencies are pinned by the committed package-lock.json; the
  # portable plugins cannot load without node_modules. Idempotent.
  local root="$1"
  if [ "${VERIFY_ONLY}" -eq 1 ]; then
    log "would install plugin dependencies in ${root} (npm install)"
    return 0
  fi
  if ! command -v node >/dev/null 2>&1; then
    die "node not found on PATH; required to install plugin dependencies. Install Node.js (with npm) and re-run."
  fi
  if ! command -v npm >/dev/null 2>&1; then
    die "npm not found on PATH; required to install plugin dependencies. Install Node.js (with npm) and re-run."
  fi
  log "Installing plugin dependencies in ${root} ..."
  ( cd "${root}" && npm install ) || die "npm install failed in ${root}"
}

log "DaverAgent bootstrap"
log "  source : ${SOURCE_ROOT}"
log "  target : ${TARGET}"
log "  remote : ${REPO_URL}"
[ "${VERIFY_ONLY}" -eq 1 ] && log "  mode   : verify-only (no writes)"
log ""

# 1. Target is the source repo itself (running in-place): just verify.
if same_path "${TARGET}" "${SOURCE_ROOT}"; then
  log "Target is the source repository; nothing to clone."
  if verify_layout "${SOURCE_ROOT}"; then log "OK: layout is valid."; else die "layout check failed."; fi
  install_plugin_deps "${SOURCE_ROOT}"
  exit 0
fi

# 2. Target absent.
if [ ! -e "${TARGET}" ]; then
  if [ "${VERIFY_ONLY}" -eq 1 ]; then
    log "would clone ${REPO_URL} -> ${TARGET}"
    install_plugin_deps "${TARGET}"
    log ""
    if verify_layout "${SOURCE_ROOT}"; then
      log "OK: source layout is valid; verify-only, no writes."
      exit 0
    fi
    die "source layout check failed."
  fi
  log "Cloning ${REPO_URL} -> ${TARGET} ..."
  mkdir -p "$(dirname "${TARGET}")"
  clone_into "${TARGET}" || die "git clone failed"
  log ""
  if verify_layout "${TARGET}"; then
    install_plugin_deps "${TARGET}"
    log "OK: installed at ${TARGET}."
    log "Next:  cd \"${TARGET}\" && bash tests/run-tests.sh"
    exit 0
  fi
  die "clone succeeded but layout check failed."
fi

# 3. Target exists and is our clone -> update.
if is_our_install "${TARGET}"; then
  if [ "${VERIFY_ONLY}" -eq 1 ]; then
    log "would update existing clone at ${TARGET} (git pull --ff-only)"
    install_plugin_deps "${TARGET}"
    log ""
    if verify_layout "${TARGET}"; then log "OK: layout is valid; verify-only, no writes."; exit 0; fi
    die "layout check failed."
  fi
  log "Updating existing clone at ${TARGET} ..."
  git -C "${TARGET}" pull --ff-only || die "git pull failed (local changes?)"
  log ""
  if verify_layout "${TARGET}"; then
    install_plugin_deps "${TARGET}"
    log "OK: updated ${TARGET}."
    exit 0
  fi
  die "update succeeded but layout check failed."
fi

# 4. Target exists but is NOT this clone -> back up, then clone fresh.
BACKUP="$(backup_name "${TARGET}")"
if [ "${VERIFY_ONLY}" -eq 1 ]; then
  log "would back up ${TARGET} -> ${BACKUP}"
  log "would clone ${REPO_URL} -> ${TARGET}"
  install_plugin_deps "${TARGET}"
  log ""
  if verify_layout "${SOURCE_ROOT}"; then log "OK: source layout is valid; verify-only, no writes."; exit 0; fi
  die "source layout check failed."
fi
log "Existing target is not a DaverAgent clone."
log "Backing up ${TARGET} -> ${BACKUP} ..."
mv "${TARGET}" "${BACKUP}" || die "could not back up ${TARGET}"
clone_into "${TARGET}" || { warn "clone failed; restoring backup"; mv "${BACKUP}" "${TARGET}"; die "git clone failed"; }
log ""
if verify_layout "${TARGET}"; then
  install_plugin_deps "${TARGET}"
  log "OK: installed at ${TARGET} (previous config backed up at ${BACKUP})."
  log "Next:  cd \"${TARGET}\" && bash tests/run-tests.sh"
  exit 0
fi
die "clone succeeded but layout check failed."
