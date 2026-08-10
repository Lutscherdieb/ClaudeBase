# The scaffold procedure

Load when executing `/base:new-project` step 4 (interview answered, preview approved). Target dir `<T>` confirmed empty.

1. **Copy the seed**: everything under `${CLAUDE_PLUGIN_ROOT}/seed/` into `<T>`, stripping the `.tmpl` suffix (`CLAUDE.md.tmpl` → `CLAUDE.md`, `.claude/settings.json.tmpl` → `.claude/settings.json`, ...). Copy, never symlink — a Sub is self-contained and committable. Skip `CANARY.txt` and skip `docs/ARCHITECTURE.md.tmpl` unless Q7 chose it.
2. **Substitute placeholders** from the interview mapping (`references/interview.md`). JSON placeholders get real JSON values (arrays/objects, `null` for "none"), not quoted strings of JSON. Remove the instructional `<!-- ... -->` scaffolder comments from PROJECT.md/README.md where they've been replaced by real content; keep the entry templates in REFERENCES.md/learning-log.md (they're for the project's future authors).
   **Verify**: `grep -rn '{{' <T>` returns nothing. A leftover placeholder is a scaffold bug — fix it now and file a lesson if the cause was a mapping gap.
3. **Compute `region_state`**: for every `BASE:<id>:v<rev>` region in the seeded files, record `{"<file>#<id>": {"rev": <rev>, "hash": "sha256:<hex>"}}` into the manifest. **Hash exactly as `/base:sync`'s `references/region-rewrite.md` specifies** (content between the marker lines, LF-normalized, trailing-newline-insensitive) — a scaffold-time hash computed differently makes every later sync report a phantom hand-edit. This is what lets `/base:sync` distinguish clean updates from hand-edited regions later — compute it from the FILES AS WRITTEN, after substitution.
   **Verify**: every region found by `grep -rn 'BASE:.*START' <T>` has a `region_state` entry, and re-hashing reproduces the stored hashes.
4. **Git** per Q10: `git init -b master`, add a `.gitattributes` (`* text=auto`, `*.sh text eol=lf`) if any scripts exist, first commit. Mode A/B: `gh repo create <name> --public|--private --source <T> --push`. Mode C: no remote. Mode D: no git — restate the named hook cost one final time.
5. **Smoke-test the machinery** (the scaffold isn't done until this passes):
   a. `.claude/base-manifest.json` parses (`python3 -m json.tool`), and `manifest.py doc-map` / `readonly-paths` / `module docs` return the interview's values.
   b. Make a trivial tracked edit under a `doc_map` source glob, write the session-start ref, run `check-doc-freshness.sh` from the Sub root → it must nudge; revert the edit.
   c. If references were declared: pipe a synthetic Write JSON for a path inside one into `protect-references.sh` → exit 2.
   d. Run `/base:doctor` → coherent status, every dormant mechanism named (e.g. verify evidence "none yet").
6. **Register**: append one row to the `subs` array in `registry/subs.json` in the local ClaudeBase checkout, **using that file's authoritative schema in `registry/README.md`** (don't retype the field list from memory — it drifted once); commit + push Base (mode C/D Subs still get registered — their row says local-only). Local path of `<T>` goes only into Base's gitignored `registry/local-paths.local.json`.
7. **Hand off** per SKILL.md step 6.

Failure handling: any step failing stops the procedure with the error surfaced — never hand over a half-scaffolded repo silently. `<T>` can be deleted and re-scaffolded cheaply before step 6; after registration, clean up the registry row too.
