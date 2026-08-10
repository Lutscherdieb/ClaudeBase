---
name: doc-audit
description: Periodic or on-demand audit of a project's OWN docs/skills/README tree as a system - NOT its product content (the project-local audit skill instantiated by /base:audit-framework covers that; the two are easy to confuse on purpose). Checks hardcoded-list drift, missing or asymmetric cross-references, self-contradictions, doc-vs-reality staleness against the doc contract, and index/routing-table accuracy. Reports findings for approval before fixing anything. Use on "/base:doc-audit", "audit the docs", "check the documentation", "is the documentation up to date", "cold-test these files", or when the check-skill-cold-test hook nudges. NOT for "audit the content/code conventions" - that's the project audit skill.
---

# /base:doc-audit — the knowledge system audits itself

A QA pass over the project's docs/skills/README tree **as a system**: does the knowledge base — the thing that *defines* the project's conventions — still agree with itself and with reality? The product-content audit (project-local, from `/base:audit-framework`) is the sibling that asks whether the *product* follows the conventions; this asks whether the conventions' own home is sound. Ground truth here is **the project's own tree and real state** (Glob/Grep the actual files, the manifest, the git status), not the external references — except when resolving a CONTRADICTION, where the evidence tools are the project's declared ground truths (REFERENCES.md routing), never an arbitrary pick between the two conflicting texts.

## Reference index

| File | Load when you're... |
|---|---|
| `references/agent-briefing.md` | spawning the parallel chunk agents — the self-contained prompt contract |

## The five categories

1. **Hardcoded-list drift** — a roster, count, or sample size baked into prose/hooks/scripts as a frozen snapshot instead of derived from the manifest, registry, or tree. A frozen-looking list is a finding *even if it isn't wrong yet* (exemplar precedent: one stale hook list silently skipped 5 of 8 targets).
2. **Missing or asymmetric cross-references** — a fact lives in doc A, is plainly relevant to doc/skill B, and B doesn't point to it; or only one direction of a two-doc relationship links. Confirmed GAPs get rows in the project's cross-reference ledger (see `/base:audit-framework`'s cross-skill-index template).
3. **Self-contradictions** — two places asserting different things about one fact. Resolve with real evidence via the REFERENCES.md routing table (grep real usage, run the verify method, consult the declared ground truth) and cite it in the fix.
4. **Doc-vs-reality staleness** — every factual claim in a contract doc's prose checked against the real code/content it describes, not against memory. AUTO regions are trusted (a hook keeps them current); hand prose is the target.
5. **Index/routing accuracy** — PROJECT.md's doc contract vs. docs that actually exist; the manifest's doc_map vs. the real tree; skill reference-index tables vs. their references/ dirs; any derived overview doc vs. its declared source of truth.

## Two run shapes — never a hook

Even the scoped shape spawns real agents and takes minutes; `check-skill-cold-test` nudges when one is due but never runs one.

- **Scoped cold test** (mandatory-weight, per the seeded CLAUDE.md doctrine-docs rule): after a new skill/doc or a structural edit. Scope to the files that changed this session (git status/diff + session ref), 2–4 chunks. The author is the person least able to see what's missing from a file they just wrote — exemplar precedent: a same-day cold test caught a skill claiming a section it didn't have, minutes after writing.
- **Full periodic sweep**: 4–6 parallel chunks over the whole doc/skill tree. Good moments: the user asks; a doc has grown 2–3× its peers; a big content batch landed; general staleness feeling. Recurring cadence is the user's `loop`/`schedule` tooling, not this skill.

## Procedure

1. **Inventory**: Glob every `.claude/skills/**/*.md`, the contract docs (PROJECT.md's table), root CLAUDE.md/README.md, REFERENCES.md, and `.claude/hooks/*` if the project carries any; `wc -l` to gauge chunks.
2. **Read the enforcement layer yourself, directly** — the project's settings.json hooks and manifest (`modules`, `doc_map`, `verify`): it's the automated-enforcement ground truth every doc's claims about "the X gate" must be checked against, and too small to delegate.
3. **Chunk along natural domain boundaries** (coupled docs together; one chunk for contract-docs-vs-reality), roughly even and coherent; fewer for a cold test, grouped by what changed.
4. **Spawn one general-purpose agent per chunk, in parallel, foreground** — not Explore (this is whole-file cross-consistency reading, not excerpt search). Prompt contract in `references/agent-briefing.md`; every agent is read-only.
5. **Synthesize centrally**: correlate (one GAP seen from both sides is one finding), de-duplicate, prioritize.
6. **Verify anything surprising before reporting it as fact** — an agent's claim is what it intended to find, not ground truth. Apparent data loss or unexpected commits: check `git status`/`git reflog` yourself and ask the user, never relay raw alarm (exemplar precedent: "missing directory" was the user's own concurrent edit).
7. **Report findings prioritized, before fixing anything** — a finding is a question, not an edit; phrasing may be deliberate; a doc's "inaccuracy" may be design intent the code hasn't caught up to. Per-item approval.
8. **Approved GAPs** get ledger rows; a fixed GAP updates its row's status rather than leaving a stale "needs link."
9. **Fixes carry evidence** like every write-back: a fix without a grep/run/ground-truth citation is a guess wearing a fix's clothes.
