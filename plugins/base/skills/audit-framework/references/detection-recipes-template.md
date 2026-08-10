# Detection-recipes template — `<project>-audit/references/detection-recipes.md`

Copy to the instantiated skill's `references/` and fill. One section per checklist row, **in the same order as the rows**, so a reader can move between the two files by position.

```markdown
# Detection recipes

One concrete command per checklist row in `../SKILL.md`, same order. Each recipe
carries its own known-legitimate exclusions: a false positive that gets
rediscovered every run is a defect in the recipe, not in the content.

## Row 1 — <check name>

**Command:**
    <a real grep/glob/script invocation, runnable from the repo root>

**Reading the output:** <what a hit means; what the expected clean output is>

**Known legitimate exclusions (do NOT report these):**
- <path or pattern> — <why it's fine>

**Bidirectional check** (when applicable — "too few" and "shouldn't exist" are
different failures and one command rarely finds both):
- Missing where required: <command>
- Present where it shouldn't be: <command>

**Blind spots:** <what this recipe cannot see, and which row or hook covers it
instead — a recipe that quietly misses a class of violation is worse than one
that admits it>
```

## Rules for writing a recipe

1. **Run it before committing it**, against the real repo, and record the actual clean-output shape — an unrun recipe is a guess.
2. **Calibrate exclusions from that run**, not from imagination; each exclusion names why it's legitimate.
3. **Prefer deriving over enumerating**: a recipe that hardcodes a file list goes stale silently (the exemplar's stale hook list skipped 5 of 8 targets). Derive the target set from the tree, the manifest, or a glob.
4. **State the blind spot** and who covers it — usually another row, a hook, or `/base:doc-audit`.
