#!/bin/bash
# check-doc-freshness (Stop, nudge)
# Rule backstopped: the docs named in PROJECT.md's documentation contract are
# how the user reads this project's state — a change to a mapped source area
# isn't done until its mapped doc is current (seeded CLAUDE.md doctrine-docs
# region). The manifest's doc_map rows ("sources" globs -> "doc") drive this;
# nothing is hardcoded (derive, don't enumerate).
# Session-aware: diffs from the session-start ref recorded by
# session-start-ref.sh, so mid-session commits are seen (exemplar friction #2
# fixed). Generalized from the exemplar's check-workflow-overview.sh, which
# was one hardwired source->doc pair; blunt on purpose the same way — a false
# positive on a non-blocking nudge costs nothing.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_LIB_DIR="$HOOK_DIR/lib"
. "$CB_LIB_DIR/common.sh"

cb_is_sub || exit 0
cb_module_enabled docs || exit 0

docmap="$(cb_manifest_query doc-map || true)"
[ -n "$docmap" ] || exit 0

changed_all="$(cb_changed_files)"
[ -n "$changed_all" ] || exit 0

flagged=""
while IFS=$'\t' read -r glob doc; do
  [ -n "$glob" ] && [ -n "$doc" ] || continue
  # Did anything under this source glob change (excluding the doc itself,
  # which may match a broad glob like "**")?
  hits="$(cb_changed_files ":(glob)$glob" | grep -vxF "$doc" || true)"
  [ -n "$hits" ] || continue
  # Was the doc itself also touched this session?
  printf '%s\n' "$changed_all" | grep -qxF "$doc" && continue
  sample="$(printf '%s\n' "$hits" | head -3 | tr '\n' ' ')"
  flagged="$flagged
  ${doc} (mapped sources changed: ${sample})"
done <<< "$docmap"

[ -z "$flagged" ] && exit 0

cb_emit "Doc-freshness check: source areas changed this session but their mapped docs didn't:${flagged}
Per the documentation contract (PROJECT.md, and CLAUDE.md's documentation rule), a change to a mapped source area isn't done until its doc is current — the docs are how this project's state is read. If the change genuinely doesn't alter anything the doc describes, this doesn't apply. This is a reminder, not a block."
exit 0
