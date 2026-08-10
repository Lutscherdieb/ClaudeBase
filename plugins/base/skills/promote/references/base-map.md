# Where a promoted rule belongs in ClaudeBase

Load when routing a generalized rule (`/base:promote` step 4). One rule, one home — plus the mechanical companions listed in the right column.

| The rule is about... | Home | Also update, in the same commit |
|---|---|---|
| A standing principle every project should follow (how lessons are written, how docs relate to changes, how references are treated) | `docs/DOCTRINE.md` — the canonical prose | the matching `BASE:doctrine-*` region in `plugins/base/seed/CLAUDE.md.tmpl` (excerpt + `v<rev>` bump), `[seed:<id>]` CHANGELOG line |
| How a Base skill behaves (a step, a gate, a better procedure) | that skill's `SKILL.md`, or a `references/<topic>.md` if it's situational (see `/base:skill-author`'s split rule) | `[plugin]` CHANGELOG line |
| A question the interview should have asked (surfaced by a hand-edit, a divergence, or "Base didn't fit") | `plugins/base/skills/new-project/references/interview.md` (question + its consumer row) | the seed template + manifest field that consumes the answer; `[seed:...]` line if a template changed |
| A machine/tooling reality (a tool's absence, a platform quirk, a preflight step) | `plugins/base/skills/repo-setup/SKILL.md` preflight table | `/base:doctor`'s checks if the degradation should be reported, not just prevented |
| A detectable content convention (something a grep/script could check) | `plugins/base/skills/audit-framework/references/checklist-template.md` + the recipes template | — |
| A docs-system drift pattern | `plugins/base/skills/doc-audit/SKILL.md`'s categories or `references/agent-briefing.md` | — |
| Something worth mechanically enforcing (the top rung: a rule that keeps getting violated) | a hook in `plugins/base/hooks/` + its wiring in `hooks/hooks.json` | **a regression case in `tests/run-hook-tests.sh`** (mandatory — an untested hook change is how the 2026-08-10 bug batch happened), `docs/DESIGN.md` §6 roster row |
| The Base↔Sub mechanics themselves (markers, manifest schema, versioning) | `docs/DESIGN.md` | the affected skill's reference file; a `migrations/<v>.md` if existing Subs need steps |

If a rule fits nowhere: that's a signal Base is missing a concept, not that the rule should be squeezed into the closest file. Say so in the PR and propose the new home explicitly.
