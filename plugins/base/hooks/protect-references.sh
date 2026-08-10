#!/bin/bash
# protect-references (PreToolUse Write|Edit, THE one blocking hook)
# Rule backstopped: declared external references/ground truths are read-only —
# "read freely, write never, at every entry point" (seeded CLAUDE.md
# doctrine-references region; registry in REFERENCES.md). A Write/Edit whose
# file_path falls under any resolved readonly ref path is denied (exit 2) with
# the doctrine quoted, mirroring the exemplar's one blocking hook shape.
# Matching lives in lib/manifest.py's check-readonly (canonicalization via
# realpath/normcase) — a bash string-prefix version was fixture-tested full of
# bypasses (case, 8.3 short names, dot-segments, trailing slashes, CRLF;
# 2026-08-10), so the choice was removed rather than patched per-case. The
# documented escape hatch for a deliberate exception is flipping
# modules.references off in .claude/base-manifest.json (a visible, logged act),
# never editing this hook or the reference silently.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_LIB_DIR="$HOOK_DIR/lib"
. "$CB_LIB_DIR/common.sh"

input="$(cat)"

cb_is_sub || exit 0
cb_module_enabled references || exit 0

fp="$(cb_file_path_from_json "$input")"
[ -n "$fp" ] || exit 0

hits="$(cb_manifest_query check-readonly "$fp" | tr '\n' ' ' | sed 's/ *$//' || true)"

[ -z "$hits" ] && exit 0

cat >&2 <<EOF
BLOCKED: ${fp} lies inside the declared read-only reference(s): ${hits}.

References/ground truths are read-only — read freely, write never (see
REFERENCES.md and CLAUDE.md's reference rule). If this task genuinely seems to
require editing a reference, stop and surface that to the user instead of
proceeding. A deliberate, user-approved exception is made by flipping
modules.references to false in .claude/base-manifest.json — a visible, logged
act — never by editing the reference quietly.
EOF
exit 2
