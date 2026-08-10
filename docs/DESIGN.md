# ClaudeBase design — the architecture contract

How the Base↔Sub system works mechanically. The doctrine (why) lives in [DOCTRINE.md](DOCTRINE.md); this file is the how. Anything here that a skill or hook implements links back from that implementation's own header comment.

## 1. Ownership buckets — the load-bearing invariant

| Bucket | Lives | Updated by | Examples |
|---|---|---|---|
| **BASE-OWNED machinery** | inside the `base` plugin | plugin version bump; overwritten freely, no merge | all generic skills, hooks, `lib/`, seed templates |
| **SEEDED-THEN-OWNED** | copied into the Sub at creation | `/base:sync` rewrites only `BASE:` marker regions / declared JSON key-paths | CLAUDE.md, README, settings.json, .gitignore |
| **PROJECT-ONLY** | the Sub | never touched by Base | PROJECT.md body, REFERENCES.md entries, project skills, source, learning log |

A Sub hand-editing anything in the first bucket, or inside a `BASE:` region, is a bug in Base (missing interview question) — see DOCTRINE.md §2.

## 2. Marker grammar

Two namespaces, deliberately distinct:

- `<!-- BASE:<region-id>:v<rev> START -->` … `<!-- BASE:END -->` — Base-owned regions inside seeded files. `<rev>` is a per-region integer; any content change to a region in the seed bumps its rev (and CHANGELOG gets a `[seed:<region-id>]` line, ≥ MINOR release). `/base:sync` compares seed rev vs Sub rev per region, and the Sub's current region content hash vs the manifest's `region_state` to detect hand-edits.
- `<!-- AUTO:<region-id> START -->` … `<!-- AUTO:END -->` — regions derived from project content by the Sub's own declared generators (`manifest.generators`), rewritten by `regen-auto-regions` strictly inside markers.

JSON files can't carry comment markers; sync ownership there is a **key-path list** documented per file. v1 owns only `settings.json`: `extraKnownMarketplaces.claudebase`, `enabledPlugins` (the `base@claudebase` entry). Keep this set tiny — key-path merging is the most fragile sync path.

## 3. The Sub manifest (`.claude/base-manifest.json`, schema 1)

The machine-readable record that makes every mechanism possible (copier's answers-file lesson). Written by `/base:new-project`, updated by `/base:sync`. Fields:

| Field | Consumed by |
|---|---|
| `project`, `created`, `profile`, `toolchain` | doctor, repo-setup preflight, promote PR metadata |
| `base_version_at_creation`, `last_synced_version` | check-base-version, sync, doctor |
| `modules` (`docs`/`verify`/`references`/`harvest`/`audit`) | every hook's fast path (silent exit when off), doctor |
| `interview` (raw answers) | sync (re-ask only new questions), adoption retrofit |
| `doc_map` (`[{sources: [globs], doc}]`) | check-doc-freshness |
| `source_globs`, `verify.{command,evidence,exempt_patterns}` | check-verify, doctor |
| `readonly_refs` (`[{id, committed_path, local}]`) — **generated from REFERENCES.md frontmatter**, machine-local paths bound via gitignored `references.local.json` | protect-references, doctor |
| `generators` (`[{trigger_globs, command, regions}]`) | regen-auto-regions |
| `region_state` (`{"<file>#<region-id>": {rev, hash}}`) | sync's hand-edit detection |
| `divergences` (deliberately kept deviations, each with a why) | sync (skip list), doctor, promote (each divergence is a Base-bug lesson) |

## 4. Versioning & propagation

Semver on `plugins/base/.claude-plugin/plugin.json`:
- **PATCH** — plugin-internal fix; no seed region touched; arrives with the plugin update, no sync needed.
- **MINOR** — new skill/hook/reference, or any seed region rev bump / new seed file; Subs run `/base:sync`.
- **MAJOR** — manifest schema bump, marker-grammar change, or any judgment-requiring migration; `migrations/<version>.md` is mandatory and sync surfaces it as explicit tasks, never auto-runs it.

CHANGELOG entries are tagged `[plugin]` or `[seed:<region-id>]` so sync can render "what you'll get." Forward pipe: marketplace auto-update / `/plugin marketplace update claudebase` + `/reload-plugins`. Backward pipe: `/base:promote` PRs, merged via the Base-side `base-release` skill (which also bumps, tags `v<semver>`, and reports affected Subs from the registry).

## 5. Hook conventions (all hooks in `plugins/base/hooks/`)

Ported from the exemplar suite:
- bash, `set -uo pipefail` (never `-e`); missing tools degrade to silent no-op via `|| true`/early exit, surfaced by doctor/preflight rather than hook noise.
- **Silent no-op fast path first**: not a Sub/Base repo → exit 0; module off → exit 0; nothing to flag → exit 0, no output.
- Nudges emit `{"systemMessage": ...}` (jq if present, sed-escape fallback) and end with **"This is a reminder, not a block."** Exactly one blocking hook exists: `protect-references` (exit 2 + stderr, quoting the doctrine and the escape hatch).
- Structured manifest queries go through **one parser**, `lib/manifest.py` (python3) — no jq/bash reimplementations (DOCTRINE.md §1.4: remove the choice). No python3 → those hooks are dormant; doctor names which.
- **Session-awareness**: `session-start-ref` records HEAD at SessionStart; Stop hooks diff `start-ref → worktree`, so mid-session commits are visible (fixes a documented exemplar friction).
- Windows: `tool_input.file_path` may arrive with JSON-doubled backslashes; `cb_normalize_path` folds to single forward slashes before matching.
- Every hook's header comment names: the rule it backstops, where that rule lives, calibration numbers with their origin, and known blind spots + who covers them instead.

**Stated limitation** (inherited from the exemplar, by design): PostToolUse hooks key on `tool_input.file_path`, so a file written by a *script* never fires them. Backstop: the audit-framework template ships a detection recipe for stale AUTO regions; run generators manually after script-driven changes.

## 6. Hook roster

| Hook | Event | Gate | Action | Mode |
|---|---|---|---|---|
| `session-start-ref` | SessionStart | Sub or Base | record HEAD → `.claude/.session/start-ref` | silent |
| `check-base-version` | SessionStart | Sub | `last_synced_version` < plugin version → name `/base:sync` | nudge |
| `protect-references` | PreToolUse Write\|Edit | Sub + `modules.references` | path under a resolved readonly ref → deny | **BLOCK** (exit 2) |
| commit-brevity | PreToolUse `Bash(git commit*)` | always | model-judged brevity standard | prompt gate |
| `regen-auto-regions` | PostToolUse Write\|Edit | Sub | run matching `generators[].command` (AUTO regions only) | auto-fix, never blocks |
| `check-doc-freshness` | Stop | Sub + `modules.docs` | `doc_map` source changed, mapped doc didn't → list pairs | nudge |
| `check-verify` | Stop | Sub + `modules.verify` + command+evidence set | source (minus exempt) newer than evidence → name the command | nudge |
| `check-skill-cold-test` | Stop | Sub or Base | new skill/doc .md, or ≥6 changed lines → scoped `/base:doc-audit` | nudge |
| `check-lesson-tagging` | Stop | learning-log exists | new entries missing `scope:`/`applications:` | nudge |

## 7. Repo detection

- **Sub**: `.claude/base-manifest.json` exists at the git root.
- **Base** (dogfooding): `.claude-plugin/marketplace.json` at the git root contains `"claudebase"`.
- Anything else: every plugin hook is a silent no-op, so a user-scope plugin install never litters unrelated repos.

## 8. Sub registry (`registry/subs.json`)

One entry per Sub: name, GitHub remote, profile, `base_version_at_creation`, last known synced version, modules. **Never local disk paths** (public repo) — those live in gitignored `registry/local-paths.local.json`. Written by `/base:new-project` (direct commit+push to Base; registry rows don't need PR ceremony), refreshed opportunistically by sync/doctor sessions. `base-release` reads it to report which Subs a release affects. Registry staleness is visible (doctor, check-base-version) but not enforced.

## 9. Plugin skill map

| Skill | Role |
|---|---|
| `new-project` | interview → scaffold a Sub from `seed/` → register |
| `repo-setup` | per-machine bootstrap: preflight, reference path binding, preferences questionnaire, concurrency procedure |
| `sync` | Base→Sub seeded-region propagation with dry-run preview + divergence ledger |
| `promote` | Sub→Base harvest: tagged generic lessons → single-rule PRs |
| `doc-audit` | audits the project's own docs/skills as a system (5 drift categories) |
| `audit-framework` | instantiates + maintains a project-local content-audit skill |
| `skill-author` | enforces skill structure at authoring time (two-tier shape etc.) |
| `doctor` | read-only status + routing; names every dormant/degraded mechanism |

Base-side only (not in the plugin): `.claude/skills/base-release` — merge harvest PRs, bump/tag/changelog, registry cascade.

## 10. Decisions & reversals

- **One plugin, not several** (2026-08-10): skills cost only a description line until invoked; per-project trimming happens via manifest `modules` flags read by every hook, which is finer-grained than plugin-level enablement and keeps "which Base version is this Sub on" a single fact. Profile packs (`base-web`, …) can join the marketplace as sibling plugins in v2 without disturbing this.
- **Claude-native sync instead of copier** (2026-08-10): the seeded layer is small and marker-delimited; a skill + marker rewriting covers it without adding a Python templating toolchain, and migrations-as-explicit-tasks replace copier's `_migrations`. Revisit only if seeded files multiply.
- **python3-only manifest parser** (2026-08-10): dual jq/bash implementations of the same queries drift; one parser + honest dormancy beats two half-parsers.
