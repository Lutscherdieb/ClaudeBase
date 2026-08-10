# Region diff & rewrite mechanics

Load when executing `/base:sync` steps 3–6.

## Marker grammar

```
<!-- BASE:<region-id>:v<rev> START -->
...region content (Base-owned)...
<!-- BASE:END -->
```

- `<region-id>` is stable forever; a rename is a MAJOR release with a migration note.
- `<rev>` is a per-region integer, bumped by Base whenever that region's content changes.
- The END marker carries no id — regions never nest, and the parser pairs each START with the next END.
- The **hash** in `region_state` covers the exact content **between** the marker lines (not the markers), normalized to LF, no trailing-newline sensitivity.

## Per-region classification

For each region in a seeded file, compare three things: seed `rev` (what Base ships now), Sub `rev` (in the Sub's marker), and `hash(current Sub content)` vs `region_state[<file>#<id>].hash`.

| Seed rev vs Sub rev | Hash matches record | Bucket | Action |
|---|---|---|---|
| equal | yes | up to date | nothing |
| equal | **no** | **hand-edited, no update pending** | report as a standing divergence; offer to restore or to record it |
| newer | yes | **clean update** | mechanical rewrite |
| newer | **no** | **conflict** | show both versions; overwrite / keep-as-divergence / manual merge |
| region absent in Sub | — | **new region** | propose insertion, with the anchor Base uses (after the named heading, or at end of file if the anchor is gone — never guess silently, ask) |
| region absent in seed | — | **retired region** | propose removal, quoting the changelog line that retired it |

A region listed in the manifest's `divergences` is skipped by default and shown once as "still diverged (reason)", so a deliberate deviation doesn't re-ask every sync.

## Rewriting

- Replace only the lines strictly between START and END; the marker lines themselves are rewritten only to update `v<rev>`.
- Preserve the file's existing line endings and its content outside the region byte-for-byte.
- After writing, re-read the file, re-parse its regions, and re-hash — store the *recomputed* hash, never the intended one (a rewrite that silently failed must not be recorded as applied).

## JSON key-path ownership (`.claude/settings.json`)

JSON can't carry markers, so sync owns a tiny declared key set:

- `extraKnownMarketplaces.claudebase`
- the `base@claudebase` entry in `enabledPlugins`

Merge only those paths; leave every other key untouched, including sibling entries in the same objects/arrays. If the user removed an owned key deliberately, treat it exactly like a hand-edited region (offer, don't force) and record it as a divergence. Keeping this set tiny is deliberate — it's the most fragile rewrite path in the system (DESIGN.md §2).

## Migrations

`migrations/<version>.md` holds the steps a text rewrite can't do (a renamed region, a manifest schema change, a split file). Sync **lists** them as explicit user-facing tasks with their version heading, and executes only the mechanical parts it can verify. Never auto-run a migration step that requires judgment; never mark `last_synced_version` past a migration whose tasks the user declined — stop at the last fully-applied version instead and say why.
