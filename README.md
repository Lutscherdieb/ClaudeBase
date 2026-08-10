# ClaudeBase

The base repository every one of my projects starts from — and reports back to.

ClaudeBase is two things in one repo:

1. **A personal [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)** shipping the `base` plugin: the generic, self-improving project machinery (skills, hooks, audit tooling) that every project auto-updates from.
2. **A seed template** that `/base:new-project` copies into each new project ("Sub") repo, tailored by a setup interview to that project's goals, references, and documentation needs.

Improvements flow both directions:

- **Base → Subs**: bump the plugin version; Subs pick machinery up automatically and pull seeded-file updates with `/base:sync`.
- **Subs → Base**: lessons learned in any project are tagged generic-vs-project at write time; `/base:promote` re-generalizes the generic ones and opens a PR here.

Status: **under construction** — see [CHANGELOG.md](CHANGELOG.md).

## Layout

| Path | What it is |
|---|---|
| `plugins/base/` | The plugin: skills, hooks, and the seed template |
| `registry/` | Which Sub projects exist and what Base version they're on |
| `migrations/` | Human-judgment upgrade notes per version, read by `/base:sync` |
| `docs/` | Design + doctrine (the canonical prose the seed excerpts from) |
