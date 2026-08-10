# Migrations

One `<version>.md` per release that needs steps `/base:sync` cannot perform mechanically — a renamed `BASE:` region, a manifest schema change, a split seed file, a convention that requires judgment about existing project content.

Mandatory for every MAJOR release (DESIGN.md §4); optional otherwise. `/base:sync` reads every migration file in `(last_synced_version, installed_version]` and **lists their steps as explicit user-facing tasks** — it never auto-runs a step requiring judgment, and it never advances `last_synced_version` past a migration whose tasks were declined.

## File shape

```markdown
# Migration to v<version>

## Why
One paragraph: what changed in Base and why existing projects can't just take a text rewrite.

## Steps
1. <imperative step, with the exact command or edit where possible>
2. ...

## Verification
How to confirm the migration actually landed (a grep, a doctor line, a test run) —
an instruction that can be silently satisfied wrongly needs a check that proves it was.

## If you skip it
What breaks or stays dormant, so declining is an informed choice rather than a silent one.
```
