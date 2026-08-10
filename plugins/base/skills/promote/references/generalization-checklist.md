# Generalization checklist

Load when rewriting a project lesson into a Base-worthy rule (`/base:promote` step 3). Work through it per rule; a rule that fails any test either gets rewritten or goes back to `scope: project`.

1. **Strip project nouns → roles.** Domain names become the role they play: "the DJ mod's sprite sheet" → "a generated asset whose entries are position-indexed"; "Log.txt" → "the verify evidence artifact"; "the game" → "the app under test". If no role name exists, that's a signal the rule may be domain-bound.
2. **The stranger test.** Read the rewritten sentence as someone working on a completely different kind of project (a web app, a data pipeline). Does it still tell them what to DO? If it only makes sense with this project's mechanics in mind, it's `scope: project`.
3. **Keep the imperative form.** The rule leads with the action, includes its verification step if the failure mode was "I thought I'd done it right", and demotes evidence after the rule (DOCTRINE.md §1). Promotion is not the moment to soften a rule into a description.
4. **Keep the evidence, mark its origin.** Cite the original `file:line`/error text/N, prefixed with the originating project ("found in <project>, 2026-08-10") so a future reader can judge how far it generalizes — and so a Base rule whose only evidence came from one domain is visibly that.
5. **Prefer removing the choice.** If the lesson can become a helper, a default, a template region, or a test case instead of a paragraph, propose that form — it's the strongest rung of the ladder that still fits a PR (DOCTRINE.md §1.4).
6. **Check for an existing home first.** Before adding a new rule, grep Base for the same fact: if a rule already covers it, the PR sharpens the existing rule (or adds its verification step) rather than adding a near-duplicate. "One convention, one home" applies to Base itself.
7. **Name the cascade.** If the rule lands in a doctrine region or a skill, check the sibling files for the same issue and say in the PR body whether they need the same change ("applied consistently" or "not applicable because X"). An unstated cascade is how Base's own docs drift out of agreement.
8. **Say what it costs.** If the rule adds a gate, a question, or work per change, state that cost in the PR body — a rule adopted without its cost visible is the kind that later gets ignored.
