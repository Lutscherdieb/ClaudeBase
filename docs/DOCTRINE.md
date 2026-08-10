# ClaudeBase doctrine — canonical prose

This file is the **single source of truth for the doctrine**. The `BASE:doctrine-*` regions in `plugins/base/seed/CLAUDE.md.tmpl` are compressed excerpts of it: edit here first, then the excerpt (bumping the region's `v<rev>` and adding a `[seed:<region-id>]` CHANGELOG line in the same edit — see CLAUDE.md's version-discipline rule). Extracted and generalized from the Cube Chaos modding repo's `CLAUDE.md` and skill system, where every one of these rules was forced into existence by a real incident.

## 1. Turn every lesson into a rule, not a war story

Improving the workflow with what a task teaches outranks finishing any individual feature. A lesson counts only once it's a **prescriptive rule telling the next session what to DO** — a "gotcha" describing what went wrong is a fact about the past; a rule is an instruction for the present. The test: *could someone follow this without already knowing the story behind it?*

Write-back form, in order:
1. **Lead with the imperative** — the action, as a step someone executes.
2. **Include the verification step** whenever the failure mode was "I thought I had done it right." An instruction that can be silently satisfied wrongly needs a check that proves it was satisfied.
3. **Keep the evidence, demote it.** `file:line` citations, exact error text (the next person greps for that string), sample sizes, occurrence counts — after the rule, never in place of it. Record failed approaches too: several of the exemplar's best sections exist only because a plausible approach silently didn't work, and that's the expensive knowledge to rediscover.
4. **Prefer removing the choice over documenting the hazard.** A helper that can't be called wrongly, a default that's always right, a region marker a script can't write outside of — each beats any amount of warning text.

**Escalation ladder** for a recurring failure: prose warning → imperative rule + verification step → audit detection recipe → hook. A rule violated *after* being written down is evidence the writing was in the wrong **form** (usually narrative instead of procedure), not that people need reminding. Precedent: the exemplar's mid-file-insertion hazard was documented as narrative in two skills and still recurred the same day it was discussed.

## 2. Write-time classification and the harvest loop

Every written-back lesson also gets a learning-log entry **in the same edit**, tagged:
- `scope: project` — bound to this project's domain; stays local.
- `scope: generic` — would hold in a different project; a Base candidate.

plus an `applications:` date list. A generic lesson **applied 2+ times** is promotion-ready: `/base:promote` re-generalizes it (project nouns → roles; test: would this sentence make sense in a different project?) and opens a PR on ClaudeBase at **single-rule granularity — never whole files** (copying a rendered file upstream destroys the template's generality; harvest the rule, not the file).

The projen principle, adopted as doctrine: **customization happens through declared options, not edits.** Needing to hand-edit a Base-owned file or `BASE:` region is always a `generic` lesson — "Base is missing an interview question / option" — and a bug in Base, not a local workaround.

## 3. Documentation is the user interface of a project

The user reads a project's state through its documentation contract (PROJECT.md). Consequences:
- A change to a mapped source area isn't done until its mapped doc is current — same weight as the verify gate. Enforced by `check-doc-freshness` via the manifest's `doc_map`; the contract is declared once, the hook derives everything.
- **Generated regions**: `AUTO:` regions are derived from project content and rewritten only by their generators, strictly inside markers — safe by construction, not by convention, which is what makes running them unconditionally in a hook acceptable. Content that must survive regeneration sits outside the markers.
- **README governance**: root README and contract docs are *not* create-late — they exist from day one and stay minimal and current. Optional deep-dive docs are create-late-ask-first (a doc that exists must be kept in sync on nearly every later change — real ongoing cost, so creating one is the user's call); once one exists, keep it current without asking again.
- **One convention, one home**: a checklist/index row names the owning doc and links; it never restates the rule. If a check doesn't cleanly belong anywhere, the convention itself hasn't been written down yet — write it into the right home first.
- **Reversals stay in place**, marked as reversed with date and reason. A retired idea that vanishes gets re-derived; one that's visible with its cost comparison doesn't.
- **Derive, don't enumerate**: no hook, doc, or script hardcodes a list (of modules, files, projects) that the manifest, registry, or tree can supply. If enumeration is unavoidable, say where the list lives and what breaks when it goes stale. (Exemplar precedent: a hardcoded mod list in a hook silently skipped 5 of 8 mods.)
- A new skill/doc file or a structural edit to one gets a scoped `/base:doc-audit` **cold test** before it counts as done — the author is the person least able to see what's missing from a file they just wrote. Wording-only fixes are exempt.

## 4. Nothing is done untested — and evidence has a standard

Every change in a project's declared source area ends with its verify method actually run and the output checked. **Proportionality is part of the gate, stated as precisely as the gate**: pure docs/wording changes (the `exempt_patterns`) skip it; a mixed edit doesn't. A gate that fires on everything gets ignored.

Evidence standard for any claim written into a doc/skill: `file:line` for the decisive example, the exact error text if one was diagnosed, sample size N when the conclusion rests on frequency, occurrence counts when it rests on prevalence. A range without its N is untrustworthy; a stale N gets flagged and refreshed, not silently trusted.

## 5. External references are read-only ground truth

Each project declares its ground truths in REFERENCES.md: what it is, where it lives, the **access method** (exact command/tool), the **comparison procedure** (how to check our output against it), and volatility. Rules:
- **Read freely, write never — at every entry point.** The rule is stated in CLAUDE.md, REFERENCES.md, and enforced by the blocking `protect-references` hook. A task that seems to require editing a reference stops and warns instead.
- **Route questions to their ground truth**: the REFERENCES.md routing table says, per domain, where the authoritative answer lives and how to escalate when the primary source runs out (fetch the live site, decompile the binary, read the upstream repo — whatever the declared escalation is).
- **Write the answer back**: a session that had to consult ground truth doesn't end until the answer is a rule in the owning doc/skill, with evidence. An un-written-back finding is unfinished work — this is what stops every session re-deriving the same conventions.

## 6. Personal vs. shared — a repo-wide invariant

Anything under version control is shareable: no real names, emails, machine-absolute paths, or session IDs. Working-style preferences (gate strictness, check-in frequency) are personal taste in gitignored `*.local.*` files with recommended defaults that apply when the file is absent; correctness rules are shared and versioned. The two never mix: a shared standard living in a personal file (a real exemplar friction) eventually breaks for every other machine.

## 7. Gates come in pairs, with the same shape at both ends

- **Preview-and-approve** (front gate): before writing a new design/feature, show what will be built — derived from the implementation actually planned, not paraphrased from the request; the divergence between those two is the whole point. Batch-present, per-item approve. Pre-empt silent-failure shapes by presenting the already-fixed design. Escalate when simple turns complex instead of silently building the complex thing.
- **Verify + doc-freshness** (back gates): see §3–4.
- **Audit findings are questions, not edits** (the gate run in reverse over existing content): a deviation may be deliberate, so a finding gets approved per-item before anything is fixed.
