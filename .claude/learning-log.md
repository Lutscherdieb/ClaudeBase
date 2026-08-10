# ClaudeBase — learning log

Append-only harvest index for Base itself. Same rules as a Sub's log (see `plugins/base/seed/.claude/learning-log.md.tmpl`): the rule lives in its home, the entry only records it.

## 2026-08-10 — reconfigure-python-stdout-to-lf
- scope: generic
- status: candidate
- rule: Any python script whose stdout is captured by bash on Windows must set `sys.stdout.reconfigure(encoding="utf-8", newline="\n")`, and the capturing helper strips `\r` as a second belt.
- home: plugins/base/hooks/lib/manifest.py (module docstring) + lib/common.sh cb_manifest_query
- evidence: Windows CPython 3.12 emits \r\n even to pipes; Git Bash $() strips only the FINAL \r\n, so every earlier line keeps a trailing \r — protect-references enforced only its LAST readonly ref, doc-freshness false-nudged on any multi-row doc_map (fixture run 2026-08-10, reproduced both ways by reordering refs).
- applications: 2026-08-10

## 2026-08-10 — canonicalize-paths-in-one-place
- scope: generic
- status: candidate
- rule: Never compare file paths with bash string prefixes on Windows — route every path-containment or path-relativization decision through one canonicalizing helper (os.path.realpath + normcase), which resolves case, 8.3 short names, dot-segments, and trailing slashes.
- home: plugins/base/hooks/lib/manifest.py (canon(), check-readonly, match-generators)
- evidence: five independent bypasses of the blocking protect-references hook in one fixture run (Spec/ vs spec/, c: vs C:, LUTSCH~1 8.3 form, src/../spec traversal, "spec/" trailing slash), plus two silent generator skips in regen-auto-regions — all closed by one canon() function (2026-08-10).
- applications: 2026-08-10

## 2026-08-10 — adversarial-fixtures-before-first-use
- scope: generic
- status: candidate
- rule: Before wiring a new hook suite live, run an adversarial per-hook fixture pass in scratch repos (empty repo, unborn HEAD, non-ASCII paths, binary rewrites, deletions, path-spelling variants) — authoring review alone does not find this class.
- home: this repo's build procedure (P2 verification gate in the implementation plan); candidate for a future /base:hook-author skill if hooks get authored per-Sub
- evidence: 18 real failures across 8 freshly-authored hooks that had passed careful authoring, all found by one parallel fixture workflow (2026-08-10).
- applications: 2026-08-10
