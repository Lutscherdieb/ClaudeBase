---
name: doctor
description: Read-only status report for a ClaudeBase Sub project - Base version freshness, module flags, divergences, unharvested lessons, stale docs. Use on "/base:doctor", "base status", "is this project up to date with Base". Never fixes anything; only reports and routes.
---

# /base:doctor — Sub status report (spike stub)

**Spike-stage stub.** The full procedure arrives in a later Base version; for now:

1. Look for `.claude/base-manifest.json` in the repo root.
   - Absent → report: "This repo is not a ClaudeBase Sub (no base-manifest.json). If it should become one, run /base:new-project for a fresh project."
   - Present → print: project name, `base_version_at_creation`, `last_synced_version`, and the `modules` flags, each on one line.
2. Compare `last_synced_version` against this plugin's own version (read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). If behind, say so and name `/base:sync`.
3. Confirm the seed canary is readable: `${CLAUDE_PLUGIN_ROOT}/seed/CANARY.txt` — print its first line. (Spike-only step; verifies seed/ ships inside the installed plugin. Remove when the real doctor lands.)

Read-only: never edit any file from this skill.
