#!/bin/bash
# check-verify (Stop, nudge)
# Rule backstopped: nothing is "done" untested (seeded CLAUDE.md
# doctrine-verify region; the method itself is PROJECT.md's verify section).
# If source files (manifest source_globs, minus verify.exempt_patterns — the
# proportionality carve-out, e.g. pure-docs edits) changed this session but
# the declared verify EVIDENCE file is older than the newest change (or
# missing), nudge with the exact command to run.
# Generalized from the exemplar's check-launch-log.sh (its Log.txt was the
# evidence file; its Text:/Description:-only exemption is the exempt_patterns
# generalization). Session-aware via the session-start ref.
# Dormant by design when verify.command or verify.evidence is unset ("auto"):
# without an evidence file there is nothing on disk to compare against —
# /base:doctor names this dormancy so it can't be mistaken for a green light.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_LIB_DIR="$HOOK_DIR/lib"
. "$CB_LIB_DIR/common.sh"

cb_is_sub || exit 0
cb_module_enabled verify || exit 0

vcmd="$(cb_manifest_query verify-command || true)"
[ -n "$vcmd" ] || exit 0
vev="$(cb_manifest_query verify-evidence || true)"
[ -n "$vev" ] || exit 0

# Build pathspecs: include each source glob, exclude each exempt pattern.
specs=()
while IFS= read -r g; do
  [ -n "$g" ] && specs+=(":(glob)$g")
done <<< "$(cb_manifest_query source-specs || true)"
[ "${#specs[@]}" -gt 0 ] || exit 0
while IFS= read -r e; do
  [ -n "$e" ] && specs+=(":(glob,exclude)$e")
done <<< "$(cb_manifest_query exempt || true)"

changed="$(cb_changed_files "${specs[@]}")"
[ -n "$changed" ] || exit 0

root="$(cb_repo_root)"
case "$vev" in
  [A-Za-z]:/*|/*) ev_path="$vev" ;;
  *) ev_path="$root/$vev" ;;
esac

stale=0
if [ ! -f "$ev_path" ]; then
  stale=1
else
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    # A source file DELETED this session is a change the evidence can't be
    # newer than — treat as stale, don't skip it (fixture-caught 2026-08-10).
    if [ ! -f "$root/$f" ]; then
      stale=1
      break
    fi
    if [ "$root/$f" -nt "$ev_path" ]; then
      stale=1
      break
    fi
  done <<< "$changed"
fi
[ "$stale" -eq 1 ] || exit 0

n="$(printf '%s\n' "$changed" | grep -c . || true)"
sample="$(printf '%s\n' "$changed" | head -3 | tr '\n' ' ')"

cb_emit "Verify check: ${n} source file(s) changed this session (${sample}...) but the verify evidence (${vev}) is missing or older than the newest change. Per PROJECT.md's verify method, run: ${vcmd} — and check its output before calling this done. Exempt patterns (pure-docs etc.) are already excluded from this check. This is a reminder, not a block."
exit 0
