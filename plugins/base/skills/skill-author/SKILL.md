---
name: skill-author
description: Structure and quality rules for authoring or restructuring any Claude Code skill in a ClaudeBase Sub (or in ClaudeBase itself) - the two-tier SKILL.md + references/ shape, description-line quality, naming collisions with plugin skills, and per-script self-documentation headers. Use whenever creating a new .claude/skills/ skill, adding a references/ file, or when a skill file is growing past what its typical trigger needs. Invoked by the seeded CLAUDE.md's documentation rules.
---

# /base:skill-author — how skills are shaped here

The exemplar repo's own convention, enforced at authoring time because its one violation (a 679-line core file, flagged by its own audit) happened by drift, not decision.

## The two-tier shape

- **`SKILL.md` (core)** holds what a *typical* trigger of this skill needs. **Split by content shape, not line count**: the moment a new section is "you'd only load this if you're doing X specifically," it goes straight into `references/<topic>.md` — don't let it accumulate in the core and wait for a size crisis.
- **`references/<topic>.md`** files are self-contained: title + a one-line "load this when..." blurb + content, readable standalone by a session that greps into it without ever seeing the index.
- Once any references exist, the core gains a **Reference index table** (`| File | Load when you're... |`). Zero reference files is a completely normal state for a small skill.

## Description-line quality

The frontmatter `description:` is the skill's only always-in-context surface. It must carry: what the skill does (one clause), concrete trigger phrases users actually type, and a disambiguation pointer when a sibling skill is confusable ("for X use Y instead" — the exemplar keeps two deliberately-confusable audit skills apart this way). Write it for the router, not the reader.

## Naming next to the plugin

Plugin skills are namespaced (`/base:doc-audit`) and a project skill does NOT override a same-named plugin skill — both stay visible. So: **never name a project skill something confusable with a `/base:*` skill**; if a project needs a specialized variant of a plugin skill's job, name it by its specialization (`<project>-audit`, not `audit`) and cross-reference both ways.

## Scripts and hooks carried by a skill

Every script/hook a skill ships opens with a header block: the rule it implements, the incident that created it, calibration numbers **with their origin**, known blind spots and who covers them instead, and any "don't 'improve' this without X" warning. This is what makes each file independently auditable (doc-audit reads them directly).

## Done-ness

A new skill or a structural edit to one isn't done until a scoped `/base:doc-audit` cold test covers it (the `check-skill-cold-test` hook nudges at ≥6 changed lines; wording-only fixes exempt) — the author is the person least able to see what's missing from a file they just wrote.
