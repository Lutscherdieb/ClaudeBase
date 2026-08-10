# Adopting ClaudeBase into an existing repo

`/base:new-project` scaffolds a fresh Sub. This is the other path: an **existing** repo — possibly one with its own mature skills, hooks, and conventions — becoming a Sub without losing what it already has. Written from the Cube Chaos modding repo (the exemplar all of ClaudeBase was extracted from) as the worked case; the steps generalize.

**The governing rule: adoption never loses content.** Where the existing repo's version of something is *better* than Base's, that difference is harvested **upstream first** (a `/base:promote` PR), and only then is the local copy replaced by the now-improved shared one. An adoption that silently overwrites a sharper local rule with a blander Base one has made both repos worse.

## Step 1 — retrofit interview

Run `/base:new-project`'s question set in **derive-then-confirm** mode: read the repo and propose each answer, ask the user to correct rather than to author. Most answers already exist somewhere:

| Interview question | Where the answer usually already lives |
|---|---|
| goal / non-goals / users | the repo's README intro and CLAUDE.md preamble |
| profile, toolchain, build/run | README "what you need" + existing scripts |
| verify method + evidence | whatever the repo already calls "done" (a test command, a launch-and-check-log loop and its log path) |
| references / ground truths | the read-only rules already written in prose ("never edit these paths"), plus the vendor docs and any decompile/inspect procedure the repo has documented |
| documentation contract + doc_map | the docs that exist and are actually maintained; map each to the source area it describes |
| generators | existing regen scripts and the hooks that call them |

## Step 2 — manifest retrofit

Write `.claude/base-manifest.json` with `base_version_at_creation: "adopted-at-v<version>"`. **Record every deliberate deviation as a day-one `divergences` entry** with its reason — an adopted repo starts with real divergences, and pretending otherwise makes the first `/base:sync` misleading.

## Step 3 — harvest before wrapping

For each `BASE:` doctrine region, locate the existing repo's equivalent prose (a mature repo usually has all of them in some form). Compare:

- **Base's is stronger or equal** → wrap/replace the local prose with the marker pair.
- **The local one is stronger** (sharper wording, a verification step Base lacks, a hard-won carve-out) → `/base:promote` it to Base *now*, merge, then adopt the improved region. This is the "never lose content" rule in practice.
- **The local one is project-specific** → it stays, outside the markers, in the project-rules section.

Documented reversals stay in place, marked as reversed. Never delete a rule during adoption just because Base has no equivalent.

## Step 4 — skill dedup

Plugin skills are namespaced (`/base:doc-audit`) and a project skill does **not** override a same-named plugin skill — both stay visible, so ambiguity must be removed deliberately:

- **Domain skills stay untouched.** They're the repo's actual value and have no Base equivalent.
- **Process skills get compared 1:1** with their Base counterparts (`<x>-doc-audit` vs `/base:doc-audit`, `<x>-repo-setup` vs `/base:repo-setup`, an existing content-audit skill vs `/base:audit-framework`'s template). Harvest any delta upstream, then delete the local copy — keeping a thin project-notes reference file for genuinely project-specific calibration (e.g. a game-root check, a domain-specific preflight) rather than the whole skill.
- **An orchestrator/router skill stays local**: routing over domain content is project knowledge. Trim only the parts that now duplicate Base's process steps, replacing them with pointers.

## Step 5 — hook dedup

- Delete local hooks that Base now ships (cold-test, commit-brevity, generic doc-freshness).
- Re-express hardwired local pairs as manifest data: a "source X changed but doc Y didn't" hook becomes a `doc_map` row; a "regen script after content edit" hook becomes a `generators` entry.
- **Keep domain hooks** that encode project-specific correctness (a DSL-safety blocker, a content-coverage check) — Base has no opinion about those. Give each one a regression case in the project's own test suite, mirroring `tests/run-hook-tests.sh`.
- Move any shared standard that was living in a personal/gitignored settings file into the shared layer (a real exemplar friction: a commit-message standard hidden in `settings.local.json` broke for every other machine).

## Step 6 — validate

1. `/base:doctor` — coherent status, every dormant mechanism named.
2. Full `/base:doc-audit` sweep — the adopted tree is exactly the "docs written by several sessions over months" case it exists for.
3. One normal working session in the repo's own domain, confirming nothing regressed and the new gates fire where expected.
4. Add the registry row.

## Risks specific to adoption

- **Double enforcement**: a local hook and a Base hook nudging the same thing is noise that teaches the user to ignore nudges. Dedup (step 5) before enabling modules, not after.
- **A doc contract that's too ambitious**: mapping every source area to a doc on day one produces constant doc-freshness nudges in a repo that never promised that much. Start with the docs actually maintained, extend later.
- **Divergence debt looking like drift**: day-one divergences (step 2) are legitimate; without their recorded reasons, a later session reads them as neglect and "fixes" them.
