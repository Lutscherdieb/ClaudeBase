# Changelog

Entries are tagged `[plugin]` (machinery — arrives with the plugin update itself) or
`[seed:<region-id>]` (seeded-file regions — applied to existing projects via `/base:sync`).

This file ships inside the plugin so `/base:sync` can read it from the installed cache.

## [Unreleased]

- `[plugin]` Initial machinery: 8 skills (new-project, repo-setup, sync, promote, doc-audit, audit-framework, skill-author, doctor), 8 hooks + shared lib, 48-case hook regression suite.
- `[seed:*]` Initial seed: CLAUDE.md with 5 doctrine regions, PROJECT.md constitution, REFERENCES.md ground-truth registry, README, settings, manifest, learning log.
