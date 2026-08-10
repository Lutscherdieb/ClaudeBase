#!/bin/bash
# check-lesson-tagging (Stop, nudge)
# Rule backstopped: every lesson written back gets a learning-log entry tagged
# with scope: (generic|project) and an applications: list AT WRITE TIME (seeded
# CLAUDE.md doctrine-writeback region). Write-time classification is what makes
# /base:promote possible at all — untagged entries are invisible to the
# harvest. This hook counts entry headers ("## ") added to
# .claude/learning-log.md this session against added "scope:" and
# "applications:" lines; more headers than tags -> nudge. Deliberately a crude
# count, not a parser: a false positive on a non-blocking nudge costs nothing.
# Gates on the log file existing, so it works in Base (which keeps its own
# learning log) as well as in Subs.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_LIB_DIR="$HOOK_DIR/lib"
. "$CB_LIB_DIR/common.sh"

root="$(cb_repo_root)"
[ -n "$root" ] || exit 0
log=".claude/learning-log.md"
[ -f "$root/$log" ] || exit 0

ref="$(cb_start_ref)"
[ -n "$ref" ] || ref="HEAD"

if git -C "$root" ls-files --error-unmatch "$log" >/dev/null 2>&1; then
  added="$(git -C "$root" diff "$ref" -- "$log" 2>/dev/null | grep '^+' | grep -v '^+++' || true)"
else
  # Still untracked: every line counts as added this session.
  added="$(sed 's/^/+/' "$root/$log" 2>/dev/null || true)"
fi
[ -n "$added" ] || exit 0

headers="$(printf '%s\n' "$added" | grep -cE '^\+## ' || true)"
scopes="$(printf '%s\n' "$added" | grep -cE '^\+[[:space:]-]*scope:' || true)"
apps="$(printf '%s\n' "$added" | grep -cE '^\+[[:space:]-]*applications:' || true)"

[ "$headers" -gt 0 ] 2>/dev/null || exit 0
if [ "$scopes" -ge "$headers" ] && [ "$apps" -ge "$headers" ]; then
  exit 0
fi

cb_emit "Lesson-tagging check: ${headers} new learning-log entr(y/ies) this session, but only ${scopes} scope: and ${apps} applications: line(s) added with them. Per CLAUDE.md's write-back rule, every entry is tagged scope: generic|project with an applications: date list at write time — untagged entries are invisible to /base:promote, so the lesson can never reach Base. This is a reminder, not a block."
exit 0
