#!/bin/bash
# session-start-ref (ClaudeBase, plugin-shipped)
# Rule backstopped: Stop-hooks must see mid-session commits, so they diff against the
# session-start HEAD recorded here instead of only the uncommitted working tree.
# (That working-tree blindness was a documented friction in the exemplar repo's Stop hooks.)
# Silent no-op outside a git repo. Never blocks anything.
set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$root" ] || exit 0
mkdir -p "$root/.claude/.session" 2>/dev/null || exit 0
{ git -C "$root" rev-parse HEAD 2>/dev/null || echo "no-head"; } > "$root/.claude/.session/start-ref"
date +%s > "$root/.claude/.session/start-time" 2>/dev/null || true
exit 0
