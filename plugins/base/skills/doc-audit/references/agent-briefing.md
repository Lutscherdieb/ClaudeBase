# Chunk-agent prompt contract

Load when spawning `/base:doc-audit`'s parallel chunk agents (procedure step 4). A fresh agent shares none of the session's context, so every prompt must be self-contained and include ALL of:

1. **The sibling disambiguation**: "You are auditing the project's OWN documentation/skill system for internal consistency — not whether its product content follows conventions (a different skill covers that)."
2. **The "one convention, one home" philosophy**: a short cross-reference that *links* to the owning doc is correct and good — do NOT flag brief pointers as duplicates; flag only genuine restatements of a rule's substance in a second home.
3. **The exact file list** for the chunk, with: "Read every listed file FULLY — no excerpts, no sampling."
4. **The finding vocabulary**, one line per finding, `[CATEGORY] file:line — one-sentence description`:
   - `GOTCHA` — a fact worth indexing (not every syntax detail)
   - `XREF` — a healthy cross-reference (cite a few as calibration, don't enumerate all)
   - `DUPLICATE` — same rule restated instead of linked (cite both locations)
   - `GAP` — relevant to another doc/skill's domain, not linked there
   - `STALE` / `CONTRADICTION` — outdated, or disagrees with something else read
   - `ROUTING-BUG` / `TABLE-DRIFT` — an index/contract/doc-map row that doesn't match reality
   - `MISSING` — a contract doc omits real, load-bearing content
   - `OK-VERIFIED` — spot-checks that DID match; keeps the report honest about what's fine, not just a bug list
5. **Read-only**: "Do not edit anything. Report only."
6. **A response-length cap** (~150–220 lines) so several chunk reports don't blow the synthesizing session's context.
7. For the contract-docs-vs-reality chunk additionally: "Check every factual claim in the doc's hand-written prose against the real code/content it describes (open those files too); trust AUTO-marker regions (generated); the doc contract table in PROJECT.md tells you what each doc promises."
