---
name: new-project
description: Create a new project repo ("Sub") from ClaudeBase - runs the setup interview (goal, non-goals, toolchain, verify method, external references, documentation contract) and scaffolds a tailored repo from the seed with a base-manifest, then registers it. Use on "/base:new-project", "new project", "create a project from Base", "start a new repo". For per-machine setup of an EXISTING Sub clone use /base:repo-setup instead.
---

# /base:new-project — interview + scaffold

Creates a Sub: a self-contained project repo carrying the seeded doctrine, a machine-readable `.claude/base-manifest.json`, and `.claude/settings.json` wiring back to the `base` plugin. The interview's whole point is that the repo comes out **trimmed to the project** — coherent goal, declared ground truths, a documentation contract — not a generic dump.

## Reference index

| File | Load when you're... |
|---|---|
| `references/interview.md` | running the interview — the full question set, defaults, and the answer→artifact mapping |
| `references/scaffold-procedure.md` | executing the scaffold — copy/substitute/git/register steps and the smoke test |

## Procedure

1. **Target directory first.** Ask where the new repo should live (suggest a sibling of existing projects if the parent dir is visible). Refuse to scaffold into a non-empty directory — list what's there and stop.
2. **Run the interview** per `references/interview.md`. Batch questions with AskUserQuestion (max 4 per call), every question shows a "(Recommended)" default. The user may say "all defaults" at any point — the interview is how they *change* defaults, not a prerequisite for sane behavior. Record every raw answer; the manifest keeps them replayable.
3. **Preview before writing** (the front gate, DOCTRINE.md §7): print the derived PROJECT.md constitution summary, the reference registry, the doc contract + doc_map, and the module flags — derived from what you'll actually write, not paraphrased from the user's words. Get an explicit OK; adjust per-item on feedback.
4. **Scaffold** per `references/scaffold-procedure.md` (copy seed → substitute all placeholders → compute `region_state` hashes → git init + first commit → optional `gh repo create` → smoke-test the hooks).
5. **Register the Sub** in ClaudeBase's `registry/subs.json` (commit + push to Base directly — registry rows need no PR ceremony). No local disk paths in the registry; those go to Base's gitignored `registry/local-paths.local.json`.
6. **Hand off**: print what to read (the Sub's README + PROJECT.md), name `/base:repo-setup` for per-machine preferences (deliberately NOT part of this interview — personal vs. shared, DOCTRINE.md §6), and remind that the first session in the Sub should confirm the `base` plugin installed from the marketplace prompt.

## Rules

- Every placeholder in every seed template has exactly one source listed in `references/interview.md`'s mapping table — a placeholder left unfilled is a scaffold bug; `grep -rn '{{' <target>` must come back empty at the end (the procedure's own verification step).
- Names are the user's call: never invent the project name, always ask (Q1) — same for anything the interview marks ASK.
- An existing repo wanting to adopt Base is NOT this skill's job — that's the adoption path (`docs/ADOPTION.md` in the ClaudeBase repo); say so and stop rather than scaffolding into it.
