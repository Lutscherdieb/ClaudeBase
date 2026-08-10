# Sub registry

`subs.json` lists every project scaffolded from ClaudeBase, so a release can answer "which projects does this affect?" (`base-release`'s blast-radius report) and so `/base:promote` PRs can name their origin.

Written by `/base:new-project` at scaffold time (direct commit + push — registry rows need no PR ceremony); refreshed opportunistically by sync/doctor sessions. Staleness is **visible, not enforced**: `check-base-version` and `/base:doctor` nag inside each Sub regardless of what this file says.

## Row schema

```json
{
  "name": "MyProject",
  "remote": "https://github.com/<owner>/MyProject",
  "profile": "cli",
  "created": "YYYY-MM-DD",
  "base_version_at_creation": "0.1.0",
  "last_known_synced_version": "0.1.0",
  "modules": { "docs": true, "verify": true, "references": true, "harvest": true, "audit": true }
}
```

`remote` is `"local-only"` for Subs created without a GitHub remote. **No local disk paths here** — this repo is public (CLAUDE.md's no-personal-data rule); machine-specific checkout paths live in gitignored `registry/local-paths.local.json`:

```json
{ "MyProject": "<absolute path on this machine>" }
```
