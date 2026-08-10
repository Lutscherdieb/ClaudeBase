# ClaudeBase — project rules

This repo is the Base that creates and maintains all Sub project repos. It is public and shared: **no personal data in version control** — no real names, emails, absolute machine-specific paths, or session IDs. Machine-local state lives in gitignored `*.local.*` files.

## What this repo is

- `plugins/base/` is a Claude Code plugin (skills + hooks + seed template), distributed via this repo's own marketplace manifest (`.claude-plugin/marketplace.json`).
- Full architecture: `docs/DESIGN.md`. Canonical doctrine prose: `docs/DOCTRINE.md`.

## Rules

- **ClaudeBase dogfoods its own doctrine.** The lesson→rule standing task, the documentation-freshness gate, and the evidence standard in `docs/DOCTRINE.md` apply to this repo itself. Lessons learned while building Base go into Base's own skills/docs in imperative rule form, evidence demoted after the rule.
- **The seed and the doctrine must not drift.** Any edit to a `BASE:` region in `plugins/base/seed/*.tmpl` bumps that region's `v<rev>` and gets a `[seed:<region-id>]` CHANGELOG line in the same edit. `docs/DOCTRINE.md` is the canonical prose; seed regions are excerpts of it — edit the doctrine first, then the excerpt.
- **Version discipline.** `plugins/base/.claude-plugin/plugin.json` `version` is the update gate for every Sub. PATCH = plugin-internal fix; MINOR = new skill/hook or any seed region rev bump; MAJOR = manifest schema / marker grammar change (mandatory `plugins/base/migrations/<v>.md`). Never change seed regions without at least a MINOR bump. Releases go through `.claude/skills/base-release`.
- **Nothing is done untested: `bash tests/run-hook-tests.sh` must be green.** Any hook or `hooks/lib/` change adds its regression case there in the same edit — every existing case is a bug that survived careful authoring review and was only caught by an adversarial fixture pass. Pure prose/doc edits are exempt.
- **A new skill file or a structural edit to one gets a scoped `/base:doc-audit` cold test** before it counts as done — same weight as the test suite, for the knowledge system instead of the code.
- **Derive, don't enumerate.** No hook or skill may hardcode a list of Subs, files, or modules that the manifest/registry can supply.
