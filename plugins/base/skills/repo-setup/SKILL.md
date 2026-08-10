---
name: repo-setup
description: Per-machine bootstrap for an EXISTING ClaudeBase Sub checkout - detects actual machine state, preflights the tools the hooks and skills assume (git, bash, python3, optionally gh/jq, plus the project's declared toolchain), binds declared external references to this machine's local paths (references.local.json), and runs the one-time personal-preferences questionnaire into gitignored .claude/preferences.local.md. Also owns the worktree-per-session concurrency procedure. Use on "/base:repo-setup", "set up this repo", "new machine", "new device", "change my preferences", "parallel session", "concurrent session", "worktree". For creating a BRAND-NEW project use /base:new-project instead.
---

# /base:repo-setup — per-machine bootstrap

A *process* skill: a session on a new machine must not silently inherit another machine's git assumptions, tool availability, local reference paths, or one person's working-style preferences as universal defaults. Run once per machine/checkout; re-run only to change something.

**Ground truth here is what's actually on this machine right now** — check by running the command (`git remote -v`, `python3 --version`), never by trusting carry-over or user self-report. A tool/platform finding this skill doesn't cover gets figured out empirically and written back into this file in the same session.

## Reference index

| File | Load when you're... |
|---|---|
| `references/concurrent-sessions.md` | a second Claude Code session might run against this checkout — the worktree isolation + gated merge-back procedure |

## Step 1 — detect current state

Summarize as a short checklist, not command dumps: is this a git repo (remote? clean? branch?); does `.claude/base-manifest.json` exist (if not: this isn't a Sub — route to `/base:new-project` or the adoption path and stop); does `.claude/preferences.local.md` exist (if yes: read it back, ask only what to change, skip to Step 4); is the `base` plugin actually installed from the marketplace (vs. running dev-mode)?

## Step 2 — tool preflight

| Tool | Needed for | If missing |
|---|---|---|
| `git` + `bash` | every hook (bash scripts diffing git state) | required — on Windows this means Git Bash (ships with Git for Windows) |
| `python3` | `lib/manifest.py` — the one manifest parser | **without it these hooks are dormant**: protect-references, check-doc-freshness, check-verify, regen-auto-regions (doctor names this too). Install python3; there is no fallback parser by design (one parser, DESIGN.md §5) |
| `gh` (optional) | promote-PRs, repo creation | manual fallback: push a branch + open the PR in the browser |
| `jq` (optional) | nicer hook JSON emission | sed fallback built into every hook; nothing breaks |
| manifest `toolchain` entries | the project's own build/verify | check each (`<tool> --version`); missing ones block the verify gate, say so plainly |

## Step 3 — bind reference paths

For every REFERENCES.md entry with `local: true`: ask where that reference lives **on this machine**, verify the path exists and looks right (spot-check a known file), and write `{"<id>": "<absolute path>"}` into `references.local.json` (gitignored). An unbound local reference means protect-references can't guard it and the routing table dead-ends — bind them all or record explicitly which are unavailable here.

## Step 4 — personal preferences questionnaire

Working-style preferences, not correctness rules (those stay as strict as written, for everyone). Personal, gitignored `.claude/preferences.local.md`; **absence = every Recommended default applies** — the questionnaire is how a user *changes* defaults, not a prerequisite. Ask via AskUserQuestion, Recommended option first, never auto-picked:

1. **Preview-and-approve gate** — "Show the derived design/spec and wait for an explicit OK before writing any new feature (Recommended)" vs. "implement, then show me."
2. **Naming check-ins** — "Always ask before inventing a user-facing name/identifier (Recommended)" vs. "pick something reasonable."
3. **Proactive write-back** — "Write learnings back into docs/skills/log unprompted after a task lands (Recommended)" vs. "only on request."
4. **Post-verify behavior** — "Leave the app/server/game running after a clean verify so I can test manually (Recommended)" vs. "shut it down."
5. **Concurrent-session workflow** (only if git mode ≥ local-git) — "Isolate a second session into its own worktree+branch with a gated merge-back (Recommended)" vs. "always edit the main tree." Only kicks in on a real concurrency signal; solo sessions unaffected.

```markdown
# Personal session preferences (local, gitignored — not shared)

- preview_gate: on | off
- ask_before_naming: on | off
- proactive_writeback: on | off
- post_verify_behavior: leave-running | shut-down
- session_git_workflow: worktree-gated | off
```

| Preference | Consumed by |
|---|---|
| `preview_gate` | the front gate (DOCTRINE.md §7) in every feature-writing session; `/base:new-project` step 3 |
| `ask_before_naming` | any session inventing user-facing names; `/base:new-project` Q1 |
| `proactive_writeback` | the write-back standing task (seeded CLAUDE.md doctrine-writeback) |
| `post_verify_behavior` | verify runs in Sub sessions |
| `session_git_workflow` | `references/concurrent-sessions.md` |

## Step 5 — wrap-up

Confirm `.claude/preferences.local.md` and `references.local.json` are gitignored (the seed's .gitignore already covers both — verify, don't re-add). Run `/base:doctor` as the closing check and hand its status to the user.
