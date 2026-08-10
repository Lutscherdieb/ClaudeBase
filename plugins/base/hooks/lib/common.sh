#!/bin/bash
# lib/common.sh — shared helpers sourced by every ClaudeBase plugin hook.
#
# Conventions every hook follows (ported from the exemplar repo's hook suite):
#   - `set -uo pipefail` (never -e: a git-less or tool-less machine degrades to a
#     silent no-op via `|| true` / early exits, never to an error the user sees).
#   - Silent no-op fast path FIRST: not a Base/Sub repo, module off, nothing to
#     flag -> exit 0 with no output.
#   - Nudges are emitted as {"systemMessage": ...} via cb_emit and always end
#     with "This is a reminder, not a block." The only blocking hook is
#     protect-references.sh (exit 2 + stderr).
#   - Structured manifest queries go through lib/manifest.py (python3). No
#     python3 -> cb_manifest_query fails -> the calling hook exits 0 silently.
#     That degradation is surfaced by /base:repo-setup's preflight and
#     /base:doctor, not by hook noise.
#   - Windows: file paths from hook JSON may use backslashes (JSON-escaped);
#     cb_normalize_path folds them to single forward slashes.
#
# Known stated limitation (documented in docs/DESIGN.md, backstopped by an
# audit recipe, inherited from the exemplar): PostToolUse hooks key on
# tool_input.file_path, so files written by a *script* (not Write/Edit) never
# fire them.

cb_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || true
}

cb_manifest_path() {
  local root
  root="$(cb_repo_root)"
  [ -n "$root" ] || return 1
  printf '%s' "$root/.claude/base-manifest.json"
}

# A "Sub" carries .claude/base-manifest.json.
cb_is_sub() {
  local m
  m="$(cb_manifest_path)" || return 1
  [ -f "$m" ]
}

# ClaudeBase itself (dogfooding) is detected by its own marketplace manifest.
cb_is_base() {
  local root
  root="$(cb_repo_root)"
  [ -n "$root" ] || return 1
  [ -f "$root/.claude-plugin/marketplace.json" ] && \
    grep -q '"claudebase"' "$root/.claude-plugin/marketplace.json" 2>/dev/null
}

# cb_emit "<msg>" — systemMessage JSON; jq if available, sed-escape fallback.
cb_emit() {
  local msg="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg msg "$msg" '{systemMessage: $msg}'
  else
    local escaped
    escaped="$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')"
    printf '{"systemMessage": "%s"}\n' "$escaped"
  fi
}

# cb_normalize_path "<path>" — backslashes (incl. JSON-doubled) -> forward
# slashes, runs of slashes collapsed. Drive letters keep their form ("E:/...").
cb_normalize_path() {
  printf '%s' "$1" | tr '\\' '/' | sed 's#//*#/#g'
}

# cb_file_path_from_json "<hook-input-json>" — tool_input.file_path, normalized.
# Empty output when absent (caller exits 0).
cb_file_path_from_json() {
  local raw
  raw="$(printf '%s' "$1" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"(.*)"$/\1/')"
  [ -n "$raw" ] || return 0
  cb_normalize_path "$raw"
}

# cb_manifest_query <subcmd> [args...] — runs lib/manifest.py against this
# repo's manifest. Fails (non-zero) when python3 or the manifest is missing.
cb_manifest_query() {
  command -v python3 >/dev/null 2>&1 || return 1
  local root
  root="$(cb_repo_root)"
  [ -n "$root" ] || return 1
  python3 "${CB_LIB_DIR}/manifest.py" "$root" "$@" 2>/dev/null
}

# cb_module_enabled <name> — true when the manifest's modules.<name> isn't
# explicitly false. Missing python3/manifest counts as NOT enabled (silent
# degradation; doctor surfaces why).
cb_module_enabled() {
  local v
  v="$(cb_manifest_query module "$1")" || return 1
  [ "$v" = "true" ]
}

# cb_start_ref — the session-start commit recorded by session-start-ref.sh,
# printed only if it still resolves to a real commit. Empty otherwise.
cb_start_ref() {
  local root ref
  root="$(cb_repo_root)"
  [ -n "$root" ] || return 0
  ref="$(head -1 "$root/.claude/.session/start-ref" 2>/dev/null || true)"
  [ -n "$ref" ] || return 0
  git -C "$root" cat-file -e "$ref^{commit}" 2>/dev/null || return 0
  printf '%s' "$ref"
}

# cb_changed_files [pathspec...] — files changed THIS SESSION: committed since
# the session-start ref (fixes the exemplar's "Stop hooks are blind to
# mid-session commits" friction), plus staged/unstaged, plus untracked.
# Deduplicated, repo-relative, one per line. Pathspecs may use ":(glob)...".
cb_changed_files() {
  local root ref
  root="$(cb_repo_root)"
  [ -n "$root" ] || return 0
  ref="$(cb_start_ref)"
  [ -n "$ref" ] || ref="HEAD"
  {
    git -C "$root" diff --name-only "$ref" -- "$@" 2>/dev/null || true
    git -C "$root" ls-files --others --exclude-standard -- "$@" 2>/dev/null || true
  } | sort -u | grep -v '^$' || true
}

# cb_version_lt <a> <b> — numeric semver compare: is a < b?
cb_version_lt() {
  local a="$1" b="$2"
  [ "$a" = "$b" ] && return 1
  local IFS=.
  local -a pa=($a) pb=($b)
  local i
  for i in 0 1 2; do
    local x="${pa[$i]:-0}" y="${pb[$i]:-0}"
    x="${x//[!0-9]/}"; y="${y//[!0-9]/}"
    [ "${x:-0}" -lt "${y:-0}" ] 2>/dev/null && return 0
    [ "${x:-0}" -gt "${y:-0}" ] 2>/dev/null && return 1
  done
  return 1
}

# Where this lib lives — set by the sourcing hook before sourcing, or derived.
: "${CB_LIB_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
