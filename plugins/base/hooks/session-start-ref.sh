#!/bin/bash
# session-start-ref (SessionStart, silent)
# Rule backstopped: Stop-hooks must see mid-session commits, so they diff
# against the session-start HEAD recorded here instead of only the uncommitted
# working tree (that blindness was a documented friction in the exemplar
# repo's Stop hooks). Runs only in a ClaudeBase Sub or in ClaudeBase itself,
# so a user-scope plugin install doesn't litter unrelated repos with .session
# dirs. Never blocks, never prints.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_LIB_DIR="$HOOK_DIR/lib"
. "$CB_LIB_DIR/common.sh"

cb_is_sub || cb_is_base || exit 0
root="$(cb_repo_root)"
[ -n "$root" ] || exit 0
mkdir -p "$root/.claude/.session" 2>/dev/null || exit 0
{ git -C "$root" rev-parse HEAD 2>/dev/null || echo "no-head"; } > "$root/.claude/.session/start-ref"
date +%s > "$root/.claude/.session/start-time" 2>/dev/null || true
exit 0
