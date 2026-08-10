---
name: promote
description: Harvest this project's generic lessons back to ClaudeBase - scans the learning log for scope-generic entries with 2+ applications, re-generalizes each into a project-agnostic rule, routes it to the right home in Base, and opens a PR via gh (one commit per rule). Use on "/base:promote", "send this back to Base", "harvest lessons", "promote to Base", or when /base:doctor reports promotion-ready candidates. The reverse direction of /base:sync.
---

# /base:promote — Sub → Base harvest

The direction almost no template system has. It works only because classification happens **at write time**: every lesson written back into this project's docs also lands in `.claude/learning-log.md` tagged `scope: generic|project` with an `applications:` list (seeded CLAUDE.md doctrine-writeback; the `check-lesson-tagging` hook nudges when a tag is missing). This skill just consumes those tags.

## Reference index

| File | Load when you're... |
|---|---|
| `references/generalization-checklist.md` | rewriting a project lesson into a Base-worthy rule |
| `references/base-map.md` | deciding which file in ClaudeBase a given rule belongs in |

## Procedure

1. **Scan** the learning log for `scope: generic`, `status: candidate`, `len(applications) >= 2`. The 2+ threshold keeps one-offs out of Base; the user can override for an obviously-general finding, but say that you're overriding and why. Also scan `manifest.divergences` — each is a standing "Base didn't fit" report and a first-class candidate.
2. **Preview the batch**: for each candidate print the current project-specific text and the proposed generalized rule side by side, plus its routed destination. Per-item approval — the user may keep one local, reword another.
3. **Re-generalize** each approved rule per `references/generalization-checklist.md`. **Single-rule granularity — never copy a whole file upstream**: a rendered, project-specific file overwrites the generality that makes Base reusable (the dotfiles-tooling lesson: naive backward sync destroys the template).
4. **Route** each rule to its Base home via `references/base-map.md`. A doctrine change touches BOTH `docs/DOCTRINE.md` (canonical) and the matching seed region (excerpt + `v<rev>` bump + `[seed:<id>]` CHANGELOG line) — never one without the other.
5. **Open the PR**: locate the Base checkout (gitignored `.claude/base.local.json`'s `base_checkout`, written by `/base:repo-setup` step 3; else `gh repo clone Lutscherdieb/ClaudeBase` into a scratch dir), branch `promote/<sub>-<slug>`, **one commit per rule**, add `[Unreleased]` CHANGELOG lines with a suggested bump level, then `gh pr create`. Body per rule: the rule, origin project, evidence, applications count/dates, suggested version bump. No `gh`: push the branch and print the compare URL for the user to open the PR manually (stated degradation, not a silent failure).
6. **Mark** each promoted entry `status: promoted-pr` with the PR URL, in the same session. (Doctor reconciles to `merged` later.)

## Rules

- **A rule that still names this project's domain isn't generalized** — the checklist's test is the gate, not a formality.
- **Never push directly to Base's default branch** from a Sub session: the PR is the review gate that keeps project-specific assumptions out of every future project.
- If a candidate turns out to be genuinely project-specific during generalization, retag it `scope: project` in the log with a one-line why — that's a result, not a failure, and it stops the candidate resurfacing every run.
