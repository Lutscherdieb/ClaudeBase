#!/bin/bash
# check-base-version (SessionStart, nudge)
# Rule backstopped: a Sub should know when Base has moved on. Machinery
# (skills/hooks) updates arrive with the plugin itself; what can lag is the
# SEEDED layer (CLAUDE.md BASE regions etc.), tracked by the manifest's
# last_synced_version. Behind the installed plugin version -> one-line nudge
# to run /base:sync. Version fields are flat strings in small JSON files, so
# plain grep parsing is fine here (no python3 dependency for this hook).
set -uo pipefail
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_LIB_DIR="$HOOK_DIR/lib"
. "$CB_LIB_DIR/common.sh"

cb_is_sub || exit 0
root="$(cb_repo_root)"

grab_version() { # grab_version <file> <key>
  grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$1" 2>/dev/null | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
}

synced="$(grab_version "$root/.claude/base-manifest.json" last_synced_version)"
plugin_json="$HOOK_DIR/../.claude-plugin/plugin.json"
current="$(grab_version "$plugin_json" version)"
[ -n "$synced" ] && [ -n "$current" ] || exit 0

cb_version_lt "$synced" "$current" || exit 0

cb_emit "Base-version check: this project last synced its seeded files at Base v${synced}; the installed base plugin is v${current}. Skills/hooks are already current (they ship with the plugin) — run /base:sync to review and pull the seeded-file updates (CLAUDE.md BASE regions etc.) with a dry-run preview first. This is a reminder, not a block."
exit 0
