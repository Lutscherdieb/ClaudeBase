---
name: doctor
description: Read-only status report for a ClaudeBase Sub project - Base version freshness, module flags, kept divergences, unharvested promotion-ready lessons, stale doc-map pairs, verify-evidence staleness, reference bindings, and dormant/degraded mechanisms. Use on "/base:doctor", "base status", "project health", "is this project up to date with Base". Never fixes anything; reports and routes to the skill that does.
---

# /base:doctor — Sub status report

Read-only, always safe to run. Its one job besides reporting: **name every dormant or degraded mechanism explicitly** — a silently-dark safety net that looks like a green light is worse than no net (DESIGN.md §5's degradation philosophy). Output is one compact checklist, each line ending in either OK, a finding, or DORMANT(reason) — with the skill/command that addresses it.

## Checks

1. **Is this a Sub?** No `.claude/base-manifest.json` → say so, point to `/base:new-project` (fresh) or `docs/ADOPTION.md` in ClaudeBase (existing repo), stop.
2. **Versions**: manifest `last_synced_version` vs installed plugin version (`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Behind → `/base:sync`. Also report `base_version_at_creation` for context.
3. **Toolchain for the machinery**: `python3` present? If not: list exactly which hooks are dormant (protect-references, check-doc-freshness, check-verify, regen-auto-regions) → `/base:repo-setup` step 2. `gh` present? If not: promote degrades to manual-PR mode.
4. **Modules**: print each flag; for every `false`, one line on what's off and why that's visible-by-design (e.g. `references: false` = the documented escape hatch is active — should it still be?).
5. **Doc freshness snapshot**: run the same computation as `check-doc-freshness` (doc_map vs session/worktree changes) and additionally a full-tree staleness pass: for each doc_map row, newest mtime under sources vs doc mtime. Stale pairs → the doc + the change that outran it.
6. **Verify gate**: command set? evidence set? If `evidence` unset/"auto" → DORMANT(no evidence artifact declared — the hook can't check mtimes; declare one in PROJECT.md + manifest when a real one exists). If set: evidence age vs newest source change.
7. **References**: every REFERENCES.md `local: true` entry bound in `references.local.json` on this machine? Each declared access method spot-checked (does the path exist / does the URL answer)? Unbound or dead → `/base:repo-setup` step 3.
8. **Harvest**: learning-log entries with `scope: generic`, `status: candidate`, 2+ applications → count + names → `/base:promote`. Entries with `status: promoted-pr` whose PR merged → note they can be marked `merged`.
9. **Audit coverage**: `modules.audit` on but no `.claude/skills/<project>-audit/` skill → DORMANT(no project audit skill instantiated) → `/base:audit-framework`. Also report whether a scoped `/base:doc-audit` cold test looks owed (the same condition `check-skill-cold-test` uses).
10. **Divergences**: list `manifest.divergences` — each is a standing "Base didn't fit" record; promotion-worthy ones (2+ applications) get flagged like #8.
11. **REFERENCES.md ↔ manifest mirror agreement**: ids/paths in `readonly_refs` match the REFERENCES.md frontmatter blocks (the mirror is generated at scaffold time — drift means someone hand-edited one side; the fix is to re-derive `readonly_refs` from REFERENCES.md's frontmatter blocks and report what changed, which `/base:repo-setup` step 3 does when it re-binds references).

Manifest parsing uses `hooks/lib/manifest.py` (`python3 <lib>/manifest.py <repo-root> <subcmd>`) — the same single parser the hooks use. Without python3, do the greppable subset (versions, modules via plain grep) and lead the report with the degradation notice.
