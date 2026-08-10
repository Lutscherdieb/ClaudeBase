# Changelog

Entries are tagged `[plugin]` (machinery — arrives with the plugin update itself) or
`[seed:<region-id>]` (seeded-file regions — applied to existing projects via `/base:sync`).

This file ships inside the plugin so `/base:sync` can read it from the installed cache.

## [Unreleased]

- `[plugin]` new-project interview Q5 now requires the verify command to actually write its evidence artifact (promoted from Wordfreq).

- `[plugin]` Initial machinery: 8 skills (new-project, repo-setup, sync, promote, doc-audit, audit-framework, skill-author, doctor); 8 shell hooks plus the inline commit-brevity prompt hook (9 wired entries) and the shared `hooks/lib`; hook regression suite.
- `[seed:*]` Initial seed: CLAUDE.md (5 doctrine regions), PROJECT.md constitution, REFERENCES.md ground-truth registry, README (footer region), .gitignore, docs/ARCHITECTURE.md, .claude/settings.json, .claude/base-manifest.json, .claude/learning-log.md.
