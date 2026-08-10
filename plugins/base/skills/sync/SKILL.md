---
name: sync
description: Pull ClaudeBase improvements into this project's seeded files - compares the manifest's last_synced_version against the installed base plugin, reads the changelog/migrations delta, and rewrites only the BASE marker regions after a dry-run preview, keeping hand-edited regions as recorded divergences. Use on "/base:sync", "update from Base", "pull Base changes", "sync seeded files", or when the check-base-version hook nudges at session start. Machinery (skills/hooks) needs no sync - it arrives with the plugin itself.
---

# /base:sync — Base → Sub propagation

Only the **seeded** layer needs syncing: skills and hooks ride the plugin and are already current the moment the plugin updates. This skill reconciles `BASE:` marker regions in the Sub's seeded files (and the small owned key-path set in `.claude/settings.json`) against the seed templates shipping in the installed plugin.

## Reference index

| File | Load when you're... |
|---|---|
| `references/region-rewrite.md` | doing the actual diff/rewrite — marker grammar, hash rules, JSON key-paths, divergence handling |

## Procedure

1. **Freshen and compare.** Ask the user to run `/plugin marketplace update claudebase` (and `/reload-plugins`) if the session hasn't; read the installed version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and `last_synced_version` from `.claude/base-manifest.json`. Equal → report "up to date" and stop (still mention any recorded divergences worth revisiting).
2. **Read the delta.** CHANGELOG entries and `migrations/<version>.md` files in `(last_synced, installed]`. They ship inside the plugin (`${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md`, `${CLAUDE_PLUGIN_ROOT}/migrations/`); if absent from the cache, fall back to `gh api` on the ClaudeBase repo, and if that fails, proceed with region diffs alone and say so.
3. **Compute the region diff** per `references/region-rewrite.md` → three buckets: clean updates, hand-edited regions, new regions/files.
4. **Dry-run preview, then per-item approval** (the Agent OS "here's what will be kept vs. replaced, confirm?" affordance; batch-present, per-item approve so one adjustment doesn't re-litigate the rest):

   | File | Region | Action | What changes |
   |---|---|---|---|
   | CLAUDE.md | doctrine-docs v1→v2 | rewrite | one-line summary of the delta |
   | README.md | readme-footer v1 | keep (divergent) | hand-edited here |

   Judgment-requiring migration steps are listed as **explicit tasks for the user**, never auto-executed.
5. **Apply approved items only**, strictly inside markers; new seeded files are written only if absent.
6. **Bookkeeping**: update `region_state` (rev + fresh hash) for every rewritten region, set `last_synced_version`, and append any kept hand-edit to `divergences` with its reason. **Every kept divergence also gets a `scope: generic` learning-log entry** — "the Base region didn't fit because X" is a missing-option bug report against Base (DOCTRINE.md §2), and that's how it reaches `/base:promote`.
7. **Post-gate**: scoped `/base:doc-audit` cold test over the changed docs, then commit (subject like `Sync seeded files to Base v<version>`).

## Rules

- **Never write outside a `BASE:` region or an owned key-path.** Everything else in a seeded file is project-owned — that boundary is what makes running this safe at all.
- **Never edit `region_state` by hand** to make a diff go away: it is the record of what Base actually last wrote, and faking it makes every future sync lie about what the Sub has.
- A region the Sub hand-edited is a **question, not an overwrite** — offer overwrite / keep-as-divergence / manual merge, and default to keeping the user's content when unsure.
