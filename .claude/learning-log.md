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

## 2026-08-11 — cold-test-before-declaring-docs-done
- scope: generic
- status: candidate
- rule: Run the scoped doc-audit cold test with an adversarial verify pass over every file authored in a session BEFORE calling the docs done — and treat "the tables/rosters in my own design doc" as the highest-yield target, checking each row against the tree it describes.
- home: docs/DOCTRINE.md §3 (cold-test rule) + plugins/base/skills/doc-audit/SKILL.md (categories 1 and 5)
- evidence: 37 confirmed findings (10 refuted) across files written the same day, incl. 6 HIGH: a registry row schema invented in one doc and contradicted in another, a "none yet" evidence sentinel the code never honored, DESIGN.md claiming all 8 hooks read module flags when 3 do, and 2 skills routing to files/steps that do not exist (2026-08-11 run).
- applications: 2026-08-11

## 2026-08-11 — assert-duplication-instead-of-tolerating-it
- scope: generic
- status: candidate
- rule: When one string genuinely must live in two files (no include mechanism exists), add a test asserting the two copies are byte-identical in the same edit that creates the second copy — never leave the duplication guarded only by prose.
- home: tests/run-hook-tests.sh ("commit-brevity prompt identical in plugin and Base settings")
- evidence: the commit-brevity prompt hook exists in both plugins/base/hooks/hooks.json and .claude/settings.json because Base deliberately does not install its own plugin; a cold-test DUPLICATE finding showed the two would drift silently with nothing to catch it (2026-08-11).
- applications: 2026-08-11

## 2026-08-11 — test-the-wiring-not-just-the-unit
- scope: generic
- status: candidate
- rule: A suite that invokes components directly must also assert the wiring/config that dispatches them in production — both directions (every wired entry resolves to a real file, every shipped file is wired).
- home: tests/run-hook-tests.sh ("wiring & doc-consistency" section)
- evidence: 48 green hook tests all invoked scripts by path, so renaming any hook file would have left the suite passing while silently unwiring the plugin (cold-test GAP, 2026-08-11).
- applications: 2026-08-11

## 2026-08-11 — translate-posix-paths-before-comparing
- scope: generic
- status: candidate
- rule: On Windows, translate any absolute POSIX-style path (`/c/Users/...`, `/tmp/...`) to its native form before comparing or resolving it — Windows Python silently resolves a leading `/` against the *current drive*, so the comparison fails without an error. Verify with a test that stores the POSIX form and asserts a native-path write is still matched.
- home: plugins/base/hooks/lib/manifest.py (`from_posix`, called by `canon`) + tests/run-hook-tests.sh "POSIX-path references"
- evidence: end-to-end validation 2026-08-11 — a reference bound as `/tmp/wcspec` resolved to `E:\tmp\wcspec`; `protect-references` returned exit 0 (allowed) on a write straight into the declared read-only reference. The 55-case suite was green at the time because every fixture used repo-relative or native paths.
- applications: 2026-08-11

## 2026-08-11 — validate-against-the-installed-artifact
- scope: generic
- status: candidate
- rule: Run the end-to-end validation against the *installed/published* artifact (plugin cache, built package), not the working checkout — packaging and path-resolution bugs only appear on that side.
- home: docs/DESIGN.md §10 (verified platform facts) + this repo's P7 validation procedure
- evidence: the POSIX-path guard bypass above surfaced only when the scaffold ran from `~/.claude/plugins/cache/...` with a real machine-local reference; the same code path looked fine in every checkout-based fixture (2026-08-11).
- applications: 2026-08-11

## 2026-08-11 — placeholder-examples-must-not-parse-as-data
- scope: generic
- status: candidate
- rule: Write every in-file example entry with angle-bracket placeholders in its *field values* (`- scope: <generic | project>`), never with realistic values — and make the scanner that consumes the file skip angle-bracket values explicitly. An example that parses as real data is indistinguishable from real data to every tool that reads the file.
- home: plugins/base/seed/.claude/learning-log.md.tmpl (entry shape) + plugins/base/skills/promote/SKILL.md step 1
- evidence: the first real promotion scan reported the seed template's own example entry as a promotion-ready candidate, because the template's `scope: generic` / `status: candidate` / two-date `applications:` line matched the scan exactly (2026-08-11).
- applications: 2026-08-11
