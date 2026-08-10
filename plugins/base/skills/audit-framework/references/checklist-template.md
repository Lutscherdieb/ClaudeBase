# Checklist template — `<project>-audit/SKILL.md`

Copy to `.claude/skills/<project>-audit/SKILL.md` and fill. Everything in angle brackets is a substitution; everything else is the architecture and stays.

```markdown
---
name: <project>-audit
description: Audit <project>'s own content/code against the conventions this project has written down - ability/logic guards, naming, structure, and any rule with a written home. Reports findings for approval before fixing anything, since a deviation may have been deliberate. Use on "audit <project>", "check conventions", "review for consistency", "sanity-check this". For auditing the DOCS themselves use /base:doc-audit instead - the two are easy to confuse on purpose.
---

# <project> content audit

Cross-cutting scan of this project's actual content against its own conventions. **This is an index, not a second copy of the rules**: every row names the one place the rule lives. If you find yourself typing out *why* a check matters here, stop — that belongs in the owning doc. If a check has no owning home, the convention hasn't been written down yet: write it there first, then add the row.

Detection commands live in `references/detection-recipes.md`, same order as the rows. The cross-reference debt ledger is `references/cross-index.md`.

## Scope

Every row carries a Scope. **Universal** = would be wrong or broken for any artifact of this kind regardless of who wrote it or what style they wanted. **House** = correct only because this project chose it; an equally functional artifact could reasonably disagree.

When auditing content this project did **not** author (a dependency, a fork, someone else's contribution), Universal rows always run; each house bucket is gated behind one yes/no question first. Buckets are a closed set — adding one updates this questionnaire in the same edit.

House buckets: <bucket-1>, <bucket-2>, ...

## Checklist

| # | Check | Owning doc/skill#section | Tier | Scope |
|---|---|---|---|---|
| 1 | <one-line statement of what must hold> | <path#section> | blocking / advisory | Universal / <bucket> |

## Procedure

1. Determine scope: is this our content or foreign? Foreign → ask the bucket questions.
2. Run the recipes for the in-scope rows (`references/detection-recipes.md`), honoring each recipe's known-legitimate-exclusions list.
3. **Report findings prioritized, before fixing anything** — a finding is a question, not an edit; per-item approval.
4. Approved fixes carry evidence (file:line / exact error text / N), same standard as any write-back.
5. A finding that reveals an unwritten convention gets the convention written into its owning doc first, then a row here.

## Growth

Every write-back that adds an audit-worthy rule (one a grep or script could check) adds its row + recipe here in the same edit. A rule that keeps getting violated after being written escalates to a hook.
```
