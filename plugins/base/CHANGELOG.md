# Changelog

Entries are tagged `[plugin]` (machinery — arrives with the plugin update itself) or
`[seed:<region-id>]` (seeded-file regions — applied to existing projects via `/base:sync`).

This file ships inside the plugin so `/base:sync` can read it from the installed cache.

## [Unreleased]

Suggested bump: MINOR (seed region revs + a new region). Harvested from the CardGenerator, ForgeModding and DixitGenerator learning logs on 2026-11-22.

- `[seed:settings.json]` **Fix:** `enabledPlugins` is now an object map (`{"base@claudebase": true}`). The array form made Claude Code reject the whole settings file, so the plugin was never enabled from project settings (hit by 3/3 Subs). `/base:sync` converts an existing array into the object form (region-rewrite.md, JSON key-path ownership). A hook-suite case now asserts the shape.
- `[seed:doctrine-verify]` v2: a check counts as evidence only after it has been seen to fail. Derive the checked list from the source of truth, strip comments, and prove the check with a planted positive and a planted negative (DOCTRINE.md §4; 6 lessons across 3 Subs).
- `[seed:doctrine-header]` v2: committed generator output prints repo-relative paths, and tracked files are grepped for machine paths before a push (DOCTRINE.md §6).
- `[seed:tooling]` v1 (new region, inserted after doctrine-verify): never send backslash or multi-line script payloads through a shell heredoc; write a file instead (DOCTRINE.md §8; 4 applications across 2 Subs).
- `[plugin]` new-project scaffold smoke test asserts `enabledPlugins` is an object; promote's base-map gains a route for silently failing tooling (DOCTRINE.md §8 + `BASE:tooling`).

## [0.0.3] — 2026-08-11

- `[plugin]` new-project interview Q5 now requires the verify command to actually write its evidence artifact (promoted from Wordfreq).

- `[plugin]` Initial machinery: 8 skills (new-project, repo-setup, sync, promote, doc-audit, audit-framework, skill-author, doctor); 8 shell hooks plus the inline commit-brevity prompt hook (9 wired entries) and the shared `hooks/lib`; hook regression suite.
- `[seed:*]` Initial seed: CLAUDE.md (5 doctrine regions), PROJECT.md constitution, REFERENCES.md ground-truth registry, README (footer region), .gitignore, docs/ARCHITECTURE.md, .claude/settings.json, .claude/base-manifest.json, .claude/learning-log.md.
