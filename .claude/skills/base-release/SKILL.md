---
name: base-release
description: ClaudeBase-side release management - review and merge promote PRs from projects, decide the semver bump, move Unreleased changelog entries, write migration notes, bump plugin.json, tag, push, and report which registered Subs the release affects. Use on "/base-release", "release Base", "cut a version", "merge a promote PR", "which projects does this affect". Base repo only; not shipped in the plugin.
---

# base-release — cutting a ClaudeBase version

Base-side only (lives in this repo's `.claude/skills/`, deliberately not in the plugin — Subs never need it).

## Merging a promote PR

1. **Review with the findings-are-questions gate**, one commit per rule: is the rule genuinely generalized (run `/base:promote`'s generalization checklist as the reviewer's rubric — especially the stranger test and "an existing home already covers this")? Is its evidence cited with its originating project? Does a doctrine change touch BOTH `docs/DOCTRINE.md` and the seed excerpt with a `v<rev>` bump?
2. **Cascade check** before merging: does the same issue exist in sibling files that the PR didn't touch? Apply consistently in the merge commit, or record why not — an unstated cascade is how Base's own docs drift.
3. **Hook changes require a regression case** in `tests/run-hook-tests.sh` in the same PR, and the suite must pass (`bash tests/run-hook-tests.sh`). No exceptions: this repo's verify gate is that suite.
4. Merge (`gh pr merge --squash` per rule-commit is fine if the PR carries several unrelated rules; prefer keeping one rule = one commit in history).

## Cutting the version

1. **Decide the bump** (DESIGN.md §4): PATCH = plugin-internal only, no seed region touched; MINOR = new skill/hook/reference or ANY seed region rev bump or new seed file; MAJOR = manifest schema, marker grammar, or any judgment-requiring migration.
2. **MAJOR (and any judgment-requiring change) writes `migrations/<version>.md`** — the steps `/base:sync` cannot do mechanically, phrased as user-facing tasks.
3. Move `[Unreleased]` entries into a version section (entries stay tagged `[plugin]` / `[seed:<region-id>]` so sync can render "what you'll get").
4. Bump `version` in `plugins/base/.claude-plugin/plugin.json` — **this is the update gate; nothing reaches any Sub without it.**
5. Run the verify gate: `bash tests/run-hook-tests.sh` (must be all-green) and `claude plugin validate ./plugins/base` + `claude plugin validate .`.
6. Commit, `git tag v<semver>`, `git push --follow-tags`.

## Reporting the blast radius

Read `registry/subs.json` and report, per Sub: its `last_synced_version`, whether this release contains `[seed:...]` entries (i.e. whether it needs `/base:sync` at all or just picks the plugin up), and whether any migration applies to its profile/modules. Subs are nudged automatically at their next session start by `check-base-version`, so this report is for the user's planning, not a push mechanism — registry staleness is visible, never enforced.
