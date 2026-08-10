# The new-project interview

Load when running `/base:new-project` step 2. Twelve questions is the ceiling — anything more belongs in later doctor/edit flows, not here (interview fatigue is a real cost). Batch via AskUserQuestion (max 4 per call, so typically 3 calls); every option list leads with the "(Recommended)" default; free-text always honored. "All defaults" is a legal answer to the whole interview.

## Questions

**Q1 — Name + one-liner** (ASK, free text, no default): project name (also the repo name) and a one-line goal.
**Q2 — Description, non-goals, users**: 2-4 sentences of what it is; what it deliberately is NOT (non-goals prevent scope creep — push for at least one); who uses it (Recommended: "me").
**Q3 — Project type** → `profile`: cli / library / web / game-mod / scripts / other. Tunes later defaults (e.g. web suggests a reference-website entry in Q6; library suggests test-command verify in Q5).
**Q4 — Languages & toolchain + build/run**: languages, package manager, and the exact commands to build/run locally. → manifest `toolchain`, README "Run & verify", .gitignore toolchain block.
**Q5 — Verify method**: "when a change is made, what proves it works?" Options by profile: test command (Recommended for library/cli) / launch-and-check-log / lint+typecheck / manual procedure / none yet. Also ask for the **evidence artifact** — the on-disk file whose freshness proves a run (test report, log file); explain that "none yet" leaves the check-verify hook dormant (doctor will keep naming that). Exempt patterns default: `["**/*.md"]`.
**Q6 — External references** (looping sub-interview; profile suggests candidates; zero entries is fine): per reference — name/id; kind (website / api-spec / binary / upstream-repo / dataset / document); location (URL → committed, local path → gitignored `references.local.json`); **access method** (exact command/tool); **comparison procedure** (concrete steps to check our output against it); volatility (live / frozen-snapshot); confirm read-only. Explain the payoff once: declared references get the blocking protect-references hook and a ground-truth routing table, which is what keeps output matching its spec (the pattern that keeps a mod's rule text matching the base game, generalized).
**Q7 — Documentation contract**: README is always in (non-negotiable — the docs are how the user reads project state). Offer: docs/ARCHITECTURE.md (Recommended for anything beyond scripts), per-module docs (usually later). For each chosen doc: one line on what it promises its reader.
**Q8 — Doc-map**: which source areas each contract doc describes (globs → doc). Offer a derived suggestion (e.g. `src/** → README.md`); editable, and expected to be refined once code exists.
**Q9 — Gate strictness**: preview-and-approve before writing new designs/features — on (Recommended) / off. "Escalate when simple turns complex" is always on, stated not asked.
**Q10 — Git mode** (with stated costs, each option names what it forfeits): A gh public repo / B gh private repo / C local-only git (no remote: no promote-PRs from this machine's CI, harvest still works via the local Base checkout) / D no git (**cost stated before choosing**: EVERY hook goes permanently silent — all of them locate the repo via `git rev-parse`, so without a repo even the blocking reference guard no-ops; if the real goal is just "no remote", pick C).
**Q11 — AUTO-region generators**: any derived artifacts (rendered previews, generated tables) + the regen command per trigger area (manifest `generators`: `trigger_globs` + `command`). Recommended: none yet — declare them when the first generator exists.
**Q12 — Module confirmation**: docs enforcement always on (stated); verify / references / harvest / audit each on (Recommended) unless Q5/Q6 made them meaningless (no verify command → verify module still on but dormant; zero references → references module off).

## Answer → artifact mapping (the placeholder ledger)

Scaffold-time values: `BASE_VERSION` (installed plugin version), `CREATED_DATE` (today), `STATUS` ("Newly scaffolded — nothing built yet."), `LAYOUT_ROWS` (from the tree actually created), `REGION_STATE_JSON` (computed hashes, see scaffold-procedure), `INTERVIEW_JSON` (all raw answers verbatim).

| Placeholder(s) | Source |
|---|---|
| `PROJECT_NAME`, `ONE_LINE_GOAL` | Q1 |
| `PROJECT_DESCRIPTION`, `NON_GOALS`, `USERS`, `DIRECTION_NOTES` | Q2 |
| `PROFILE` | Q3 |
| `TOOLCHAIN_JSON`, `TOOLCHAIN_IGNORES`, `BUILD_RUN` | Q4 |
| `VERIFY_COMMAND(_JSON)`, `VERIFY_EVIDENCE(_JSON)`, `VERIFY_EXEMPT(_JSON)`, `VERIFY_DESCRIPTION`, `QUALITY_BARS` | Q5 (+Q9 note in quality bars) |
| `ROUTING_ROWS`, `REFERENCE_SECTIONS`, `REFERENCES_SUMMARY`, `READONLY_REFS_JSON` | Q6 |
| `DOC_CONTRACT_ROWS`, `ARCHITECTURE_OVERVIEW/COMPONENTS/DECISIONS` (only if chosen) | Q7 |
| `DOC_MAP_JSON`, `SOURCE_GLOBS_JSON` | Q8 |
| `MODULE_VERIFY/REFERENCES/HARVEST/AUDIT` | Q12 |
| `GENERATORS_JSON` | Q11 |
| `PROJECT_RULES` | "(none yet — grows via the write-back task)" unless the interview surfaced one |

Extending this interview: a new question must name its consumer (which placeholder/manifest field) in this table in the same edit — a question without a consumer is trivia; a placeholder without a question is a scaffold bug. When `/base:promote` lands an "interview gap" PR, it edits this file plus the seed template that needed the new value.
