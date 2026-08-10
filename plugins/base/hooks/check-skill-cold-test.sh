#!/bin/bash
# check-skill-cold-test (Stop, nudge)
# Rule backstopped: a new skill/doc file, or a structural edit to one, isn't
# done until a scoped /base:doc-audit cold-test pass covers the changed files —
# same weight as the verify gate, just for the knowledge system instead of the
# product (seeded CLAUDE.md doctrine-docs region). Ported from the exemplar's
# check-skill-cold-test.sh, session-aware (sees mid-session commits), and
# watching BOTH .claude/skills/** (Subs and Base) and plugins/*/skills/**
# (Base's plugin skills — the pathspec simply never matches elsewhere).
# Threshold: any brand-new .md file, or an existing one with >=6 changed lines.
# 6 is the exemplar's calibration (first real session, 2026-08-02: structural
# additions landed at 6-10 changed lines, pure wording nits at 1-4) —
# recalibrate here if a future session finds it too noisy or too quiet.
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_LIB_DIR="$HOOK_DIR/lib"
. "$CB_LIB_DIR/common.sh"

cb_is_sub || cb_is_base || exit 0

THRESHOLD=6
root="$(cb_repo_root)"
specs=(":(glob).claude/skills/**/*.md" ":(glob)plugins/*/skills/**/*.md")

ref="$(cb_start_ref)"
[ -n "$ref" ] || ref="HEAD"

flagged=""

# New files (untracked, or added since the session-start ref).
new_files="$(
  {
    git -C "$root" ls-files --others --exclude-standard -- "${specs[@]}" 2>/dev/null || true
    git -C "$root" diff --name-only --diff-filter=A "$ref" -- "${specs[@]}" 2>/dev/null || true
  } | sort -u | grep -v '^$' || true
)"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  flagged="$flagged $f(new)"
done <<< "$new_files"

# Existing files with THRESHOLD+ changed lines this session.
mod_files="$(git -C "$root" diff --name-only --diff-filter=M "$ref" -- "${specs[@]}" 2>/dev/null | sort -u || true)"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  numstat="$(git -C "$root" diff --numstat "$ref" -- "$f" 2>/dev/null | head -1)"
  # numstat "-<TAB>-" means git now sees the file as binary (e.g. rewritten
  # UTF-16 by a stray Out-File) — the most structural change possible, never
  # silence (fixture-caught 2026-08-10).
  case "$numstat" in
    -*)
      flagged="$flagged $f(rewritten-as-binary)"
      continue
      ;;
  esac
  changed="$(printf '%s' "$numstat" | awk '{print $1+$2}')"
  [ -n "$changed" ] || changed=0
  if [ "$changed" -ge "$THRESHOLD" ] 2>/dev/null; then
    flagged="$flagged $f(+${changed} lines)"
  fi
done <<< "$mod_files"

[ -z "$flagged" ] && exit 0

cb_emit "Cold-test check: these skill/doc files look new or substantially changed this session:${flagged}. Per CLAUDE.md's documentation rule, a new skill (or a structural edit to one) isn't done until a scoped /base:doc-audit cold-test pass covers the changed files. Doesn't apply to small wording-only fixes. This is a reminder, not a block."
exit 0
