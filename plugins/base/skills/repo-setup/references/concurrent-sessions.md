# Concurrent sessions — worktree isolation + gated merge-back

Load when a second Claude Code session might run against the same Sub checkout. Generalized from the exemplar repo's procedure; gated by the `session_git_workflow` preference (default: worktree-gated).

**When this kicks in — two signals only** (a normal solo session is never affected):
1. Another session's worktree for this repo already exists (`git worktree list` shows one under the sessions dir), or
2. the user says another session is coming / already open.

**Why worktree-per-session, not branch-per-session:** two sessions on one working tree fight over the same files regardless of branches — checkout switches yank files out from under the other session mid-edit. A worktree gives each session its own directory *and* branch; the shared object store keeps it cheap.

## Setup (second and later sessions)

1. `git worktree add ../<repo>-session-<short-id> -b session/<short-id>` — sibling dir, never nested inside the repo.
2. Work entirely inside that directory. Standing authorization: commit freely *on the session branch* — mid-session commits are safe here and the Stop hooks stay accurate via the session-start ref.
3. Machine-local files the tree needs but git doesn't carry (e.g. `references.local.json`, `.claude/preferences.local.md`) are copied — not shared — into the worktree.

## Merge-back (gated, never automatic)

1. Run the project's verify method inside the worktree first — a session branch merges only green.
2. `git merge --no-ff session/<short-id>` from the main tree (or rebase if the user prefers linear history).
3. **Any conflict in a file the other session also touched → stop and hand the conflict to the user** — never auto-resolve concurrent human-relevant edits.
4. After merge: `git worktree remove <dir>`, `git branch -d session/<short-id>`.

Requires local git at minimum — mode "no git" has no isolation primitive; a user there who wants parallel sessions moves to local git first (stated cost in the interview's Q10).
