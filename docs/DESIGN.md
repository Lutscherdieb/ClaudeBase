# ClaudeBase design — the architecture contract

How the Base↔Sub system works mechanically. The doctrine (why) lives in [DOCTRINE.md](DOCTRINE.md); this file is the how. Every hook and script header names the rule it implements; where that rule is a mechanic of this file (markers, manifest fields, the one-parser rule), the header cites `docs/DESIGN.md` by section.

## 1. Ownership buckets — the load-bearing invariant

| Bucket | Lives | Updated by | Examples |
|---|---|---|---|
| **BASE-OWNED machinery** | inside the `base` plugin | plugin version bump; overwritten freely, no merge | all generic skills, hooks, `lib/`, seed templates |
| **SEEDED-THEN-OWNED** | copied into the Sub at creation | `/base:sync` rewrites only `BASE:` marker regions / declared JSON key-paths | CLAUDE.md, README (both carry regions), settings.json (key-paths) |
| **SEEDED ONCE** | copied at creation, then fully the Sub's | never updated by Base — no marker, no key-path; a Base improvement here reaches only *new* projects | .gitignore, PROJECT.md, REFERENCES.md, docs/ARCHITECTURE.md, learning-log |
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
| `modules` (`docs`/`verify`/`references`/`harvest`/`audit`) | the fast path of the hooks that own each flag — `docs`→check-doc-freshness, `verify`→check-verify, `references`→protect-references; `harvest`→`/base:promote`, `audit`→`/base:audit-framework` + doctor (skill-level, not hook-level). Every flag has exactly one owner; a flag nothing reads is a bug in this table or in the owner |
| `interview` (raw answers) | `/base:promote` (an "interview gap" PR quotes the answers that were given), adoption retrofit, and any future re-ask flow. Written by scaffold, read rarely — deliberately, it's the record that makes later reconstruction possible |
| `doc_map` (`[{sources: [globs], doc}]`) | check-doc-freshness |
| `source_globs`, `verify.{command,evidence,exempt_patterns}` | check-verify, doctor |
| `readonly_refs` (`[{id, committed_path, local}]`) — **generated from REFERENCES.md frontmatter**, machine-local paths bound via gitignored `references.local.json` | protect-references, doctor |
| `generators` (`[{trigger_globs, command}]`) | regen-auto-regions |
| `region_state` (`{"<file>#<region-id>": {rev, hash}}`) | sync's hand-edit detection |
| `divergences` (deliberately kept deviations, each with a why) | sync (skip list), doctor, promote (each divergence is a Base-bug lesson) |

## 4. Versioning & propagation

Semver on `plugins/base/.claude-plugin/plugin.json`:
- **PATCH** — plugin-internal fix; no seed region touched; arrives with the plugin update, no sync needed.
- **MINOR** — new skill/hook/reference, or any seed region rev bump / new seed file; Subs run `/base:sync`.
- **MAJOR** — manifest schema bump, marker-grammar change, or any judgment-requiring migration; `plugins/base/migrations/<version>.md` is mandatory and sync surfaces it as explicit tasks, never auto-runs it.

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

Eight shell hooks in `plugins/base/hooks/` plus one inline `prompt` hook (commit-brevity) wired directly in `hooks.json` — nine wired entries, eight files.

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
- Anything else: every plugin hook is a silent no-op, so a user-scope plugin install never litters unrelated repos — **with two deliberate exceptions**, each stated in its own header: `check-lesson-tagging` fires wherever a `.claude/learning-log.md` exists (having one is opting in, and a repo mid-adoption has the log before the manifest), and the `commit-brevity` prompt hook is always on (it judges a message, touches nothing, and the standard isn't project-scoped).

**Base does not install its own plugin.** It wires the hooks it wants directly in `.claude/settings.json` by repo-relative path, because the working copy *is* the source. Enabling `base@claudebase` here would double-fire every hook; if that's ever wanted, remove the local wiring in the same edit.

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

## 10. Verified platform facts (spike, 2026-08-11)

Everything the architecture assumed about Claude Code plugins, confirmed by running it — not by reading docs:

| Assumption | Result |
|---|---|
| One repo can be marketplace + plugin host | `claude plugin marketplace add Lutscherdieb/ClaudeBase` then `plugin install base@claudebase` both succeed |
| Non-standard plugin dirs survive installation | **`seed/` ships intact** in the cache, dotfiles included (`.gitignore.tmpl`, `.claude/*.tmpl`) — so `/base:new-project` and `/base:sync` read templates from `${CLAUDE_PLUGIN_ROOT}/seed/` with no clone. `CHANGELOG.md` and `migrations/` ship too |
| Version bump propagates | bump `plugin.json` → push → `plugin marketplace update` + `plugin update` → `updated from 0.0.1 to 0.0.2` |
| Installed layout | `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` — **versioned side by side**, so a Sub pinned to an older version keeps its own copy. Read-only from a consuming session; edits go to the Base checkout and come back through a version bump |
| Dev loop | `claude --plugin-dir <checkout>/plugins/base` exposes `/base:*` skills and fires plugin hooks without installing — this is how Base changes are tested from inside a Sub |
| Local marketplace cache | `~/.claude/plugins/marketplaces/claudebase/` is a full git clone of Base; useful for `/base:promote` when no other checkout is known |

The documented fallback (moving `seed/` under `skills/new-project/`) is therefore **not needed** and should not be applied.

## 11. Decisions & reversals

- **One plugin, not several** (2026-08-10): skills cost only a description line until invoked; per-project trimming happens via manifest `modules` flags read by every hook, which is finer-grained than plugin-level enablement and keeps "which Base version is this Sub on" a single fact. Profile packs (`base-web`, …) can join the marketplace as sibling plugins in v2 without disturbing this.
- **Claude-native sync instead of copier** (2026-08-10): the seeded layer is small and marker-delimited; a skill + marker rewriting covers it without adding a Python templating toolchain, and migrations-as-explicit-tasks replace copier's `_migrations`. Revisit only if seeded files multiply.
- **python3-only manifest parser** (2026-08-10): dual jq/bash implementations of the same queries drift; one parser + honest dormancy beats two half-parsers. All path containment/relativization lives there too — bash string-prefix matching was fixture-tested full of Windows bypasses (case, 8.3 names, dot-segments, trailing slashes).
- **CHANGELOG.md and `migrations/` live inside `plugins/base/`, not at the repo root** (2026-08-11): `/base:sync` must read them from the installed plugin cache, and a root copy plus a plugin copy is two homes for one fact — the duplication the doctrine forbids. The root README links to them instead.
- **`tests/run-hook-tests.sh` is Base's own verify method** (2026-08-11): 48 cases, every one a bug an adversarial fixture pass actually found in hooks that had passed authoring review. A hook change without a case here is how that batch happened; `base-release` gates on the suite being green.
