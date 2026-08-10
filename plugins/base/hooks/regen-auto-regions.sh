#!/bin/bash
# regen-auto-regions (PostToolUse Write|Edit, auto-fix, non-blocking)
# Rule backstopped: AUTO regions (<!-- AUTO:<id> START --> ... <!-- AUTO:END -->)
# inside hand-written docs are derived from project content and never
# hand-edited; the generators declared in the manifest keep them current.
# Generalized from the exemplar's regen-readme-previews.sh: safe by
# construction (a generator only ever rewrites between its markers), so
# running unconditionally on every matching edit is cheap and cannot clobber
# hand-written prose. A generator crash is reported to stderr but NEVER blocks
# the edit — this hook keeps derived regions in sync; it does not gate
# correctness.
# Known stated limitation (inherited, documented in docs/DESIGN.md): a file
# written by a script rather than Write/Edit never fires this hook — run the
# generator manually after script-driven content changes.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_LIB_DIR="$HOOK_DIR/lib"
. "$CB_LIB_DIR/common.sh"

input="$(cat)"

cb_is_sub || exit 0

fp="$(cb_file_path_from_json "$input")"
[ -n "$fp" ] || exit 0

root="$(cb_repo_root)"
# Relativization + glob matching live in manifest.py (canonicalized realpath
# comparison) — a bash prefix-strip missed lowercase drive letters and 8.3
# short-name spellings of the same file (fixture-caught 2026-08-10).
cmds="$(cb_manifest_query match-generators "$fp" || true)"
[ -n "$cmds" ] || exit 0

while IFS= read -r cmd; do
  [ -n "$cmd" ] || continue
  if ! output="$(cd "$root" && bash -c "$cmd" 2>&1)"; then
    echo "WARNING: AUTO-region generator failed after editing ${fp}: ${cmd}" >&2
    echo "$output" >&2
  fi
done <<< "$cmds"

exit 0
