---
name: audit-framework
description: Instantiates and maintains a PROJECT-LOCAL content audit skill (named <project>-audit) that checks the project's actual product/content/code against its own conventions - the sibling of /base:doc-audit, which audits the docs themselves; the two are easy to confuse on purpose. Use on "/base:audit-framework", "set up an audit skill", "audit the content", "check conventions" (first time), or when a write-back adds an audit-worthy rule and the checklist needs a row. The instantiated skill, once created, handles the actual audits.
---

# /base:audit-framework — a content audit for every project

A fresh Sub has no conventions to audit yet — they accumulate through the write-back task. This skill creates the project-local audit skill the moment there's something to check, and defines how it grows. The instantiated skill lives at `.claude/skills/<project>-audit/` (project-named, per `/base:skill-author`'s collision rule) and follows the exemplar's proven architecture:

## The architecture the instantiated skill must keep

1. **Checklist-as-index.** Every checklist row is one line: `Check | Owning doc/skill#section | Tier | Scope` — it *links* to the one home of the convention, never restates it. If writing a row makes you explain *why* the check matters, stop: that content belongs in the owning doc; if no owning home exists, the convention hasn't been written down yet — write it there first, then add the row.
2. **Universal vs. house-convention Scope.** Per row: would this be wrong/broken for *any* artifact of this kind, regardless of who wrote it (Universal) — or only because this project chose to do it this way, where an equally functional artifact could reasonably disagree (a named house bucket)? Buckets are a closed set; adding one updates the scope questionnaire in the same edit. Auditing third-party/foreign artifacts runs Universal rows always and gates each house bucket behind a yes/no question.
3. **Detection recipes file** (`references/detection-recipes.md`): one concrete grep/script per checklist row, in the same order, each carrying its own known-legitimate-exclusions list ("don't report these") so false positives are priced in per-recipe, not rediscovered per-run.
4. **Cross-reference ledger** (`references/cross-index.md`): the tracked-debt table for knowledge that lives in one place but is relevant elsewhere — `Topic | Lives at | Also relevant to | Status`, statuses `needs link` / `linked` / `resolved` / `needs checklist row`. Fed live by write-backs and in batch by `/base:doc-audit` GAPs.
5. **Findings are questions, not edits.** Report prioritized findings; the creator may have deliberately deviated; wait for per-item approval before fixing; approved fixes carry evidence.

## Instantiation procedure (first run in a Sub)

1. Confirm no `<project>-audit` skill exists yet; read PROJECT.md (quality bars) and CLAUDE.md's project-specific rules for the first checklist candidates.
2. Copy `references/checklist-template.md` → `.claude/skills/<project>-audit/SKILL.md`, filling the project name, the initial rows (only conventions that already have a written home), and the scope buckets that actually apply.
3. Copy `references/detection-recipes-template.md` → its `references/detection-recipes.md`; write one real recipe per initial row and run each once to calibrate exclusions.
4. Create an empty `references/cross-index.md` from the ledger shape above.
5. Scoped `/base:doc-audit` cold test over the new skill (the cold-test gate applies to this skill like any other).

## The growth rule (standing, wired into the seeded write-back doctrine)

Every write-back that adds an **audit-worthy** rule (one a grep/script could check) adds its checklist row + recipe in the same edit. A rule violated after being written down escalates up the ladder: recipe → hook proposal (DOCTRINE.md §1).
