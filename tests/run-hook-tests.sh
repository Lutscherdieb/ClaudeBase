#!/bin/bash
# ClaudeBase hook regression suite — this repo's own verify method.
#
# Every case below is a bug that was actually found by an adversarial fixture
# pass (2026-08-10) against hooks that had already passed careful authoring
# review, plus the happy paths those fixes must not break. Run from the repo
# root: bash tests/run-hook-tests.sh   (writes tests/last-run.txt as evidence)
#
# Adding a case: a hook bug found in the wild gets a case here in the same
# edit as the fix — that's the escalation ladder's "verification step" rung.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS="$REPO/plugins/base/hooks"
LIB="$HOOKS/lib"
PASS=0; FAIL=0; FAILED_NAMES=""

pass() { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES
    - $1: $2"; printf '  FAIL %s\n       %s\n' "$1" "$2"; }
check() { # check <name> <condition-result> <detail>
  if [ "$2" = "0" ]; then pass "$1"; else fail "$1" "$3"; fi
}

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# ---------------------------------------------------------------- fixtures --
MANIFEST_DEFAULT='{"schema":1,"project":"fixture","created":"2026-08-10",
"base_version_at_creation":"0.0.1","last_synced_version":"0.0.1","profile":"cli",
"toolchain":["python3"],
"modules":{"docs":true,"verify":true,"references":true,"harvest":true,"audit":true},
"doc_map":[{"sources":["src/**"],"doc":"README.md"}],"source_globs":["src/**"],
"verify":{"command":"bash run-tests.sh","evidence":"test-report.txt","exempt_patterns":["**/*.md"]},
"readonly_refs":[{"id":"spec","committed_path":"spec"}],
"generators":[{"trigger_globs":["data/**"],"command":"bash gen.sh"}],
"region_state":{},"divergences":[]}'

mkfixture() { # mkfixture <name> [manifest-json] -> prints path
  local d="$TMPROOT/$1"
  mkdir -p "$d/src" "$d/spec" "$d/data" "$d/.claude"
  ( cd "$d"
    git init -q -b master
    git config user.email t@t.t; git config user.name t
    printf 'int main(){}\n' > src/main.c
    printf '# readme\n' > README.md
    printf 'spec text\n' > spec/notes.txt
    printf 'echo gen-ran > gen-ran.txt\n' > gen.sh
    printf '%s' "${2:-$MANIFEST_DEFAULT}" > .claude/base-manifest.json
    git add -A >/dev/null 2>&1; git commit -qm init >/dev/null 2>&1
    mkdir -p .claude/.session; git rev-parse HEAD > .claude/.session/start-ref )
  printf '%s' "$d"
}
run_hook()  { ( cd "$1" && bash "$HOOKS/$2" </dev/null 2>"$TMPROOT/stderr" ); }        # Stop/SessionStart
pipe_hook() { ( cd "$1" && printf '%s' "$3" | bash "$HOOKS/$2" 2>"$TMPROOT/stderr" ); } # Pre/PostToolUse
json_fp()   { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }

echo "== lib/manifest.py =="
F="$(mkfixture libtest)"
out="$(python3 "$LIB/manifest.py" "$F" doc-map | od -c | grep -c '\\r' || true)"
check "manifest.py emits LF-only (no CR)" "$([ "$out" = "0" ] && echo 0 || echo 1)" "found CR in output"
out="$(python3 "$LIB/manifest.py" "$F" module docs)"
check "module docs -> true" "$([ "$out" = "true" ] && echo 0 || echo 1)" "got '$out'"
out="$(python3 "$LIB/manifest.py" "$F" match-generators data/a/b.csv)"
check "** crosses dirs" "$([ "$out" = "bash gen.sh" ] && echo 0 || echo 1)" "got '$out'"
out="$(python3 "$LIB/manifest.py" "$F" match-generators src/x.c)"
check "non-matching path -> empty" "$([ -z "$out" ] && echo 0 || echo 1)" "got '$out'"
out="$(python3 "$LIB/manifest.py" "$F" match-generators ./data/x.csv)"
check "leading ./ normalized" "$([ "$out" = "bash gen.sh" ] && echo 0 || echo 1)" "got '$out'"
python3 "$LIB/manifest.py" "$TMPROOT/nonexistent" module docs >/dev/null 2>&1
check "missing manifest -> exit 3" "$([ "$?" = "3" ] && echo 0 || echo 1)" "wrong exit code"

echo "== lib/common.sh =="
vlt() { CB_LIB_DIR="$LIB" bash -c ". '$LIB/common.sh'; cb_version_lt '$1' '$2'"; }
vlt 1.2.0 1.10.0;  check "1.2.0 < 1.10.0 (numeric)" "$?" "lexical compare regression"
vlt 1.10.0 1.2.0 && r=1 || r=0; check "1.10.0 not < 1.2.0" "$r" "wrong direction"
vlt 0.0.1-rc1 0.0.1; check "pre-release < release" "$?" "pre-release ordering"
vlt 1.0.0 1.0.0 && r=1 || r=0; check "equal not <" "$r" "equal compared as less"
out="$(CB_LIB_DIR="$LIB" bash -c ". '$LIB/common.sh'; cb_normalize_path 'E:\\\\foo\\\\bar'")"
check "backslash normalization" "$([ "$out" = "E:/foo/bar" ] && echo 0 || echo 1)" "got '$out'"
out="$(CB_LIB_DIR="$LIB" bash -c ". '$LIB/common.sh'; cb_emit 'he said \"hi\"'" | python3 -c 'import json,sys; print(json.load(sys.stdin)["systemMessage"])')"
check "cb_emit valid JSON w/ quotes" "$([ "$out" = 'he said "hi"' ] && echo 0 || echo 1)" "got '$out'"

echo "== session-start-ref.sh =="
D="$TMPROOT/empty-repo"; mkdir -p "$D/.claude"; ( cd "$D" && git init -q -b master && printf '%s' "$MANIFEST_DEFAULT" > .claude/base-manifest.json )
run_hook "$D" session-start-ref.sh
out="$(cat "$D/.claude/.session/start-ref" 2>/dev/null)"
check "unborn HEAD -> exactly 'no-head'" "$([ "$out" = "no-head" ] && echo 0 || echo 1)" "got '$(printf '%s' "$out" | tr '\n' '|')'"
D="$TMPROOT/plain-repo"; mkdir -p "$D"; ( cd "$D" && git init -q -b master )
run_hook "$D" session-start-ref.sh
check "non-Sub repo -> no .session dir" "$([ ! -d "$D/.claude/.session" ] && echo 0 || echo 1)" "created state in a non-Sub repo"

echo "== protect-references.sh =="
F="$(mkfixture protect)"
for p in "spec/notes.txt" "Spec/notes.txt" "src/../spec/notes.txt" "$F/spec/notes.txt"; do
  pipe_hook "$F" protect-references.sh "$(json_fp "$p")" >/dev/null; rc=$?
  check "blocks '$p'" "$([ "$rc" = "2" ] && echo 0 || echo 1)" "exit $rc (expected 2 = blocked)"
done
pipe_hook "$F" protect-references.sh "$(json_fp "specification.txt")" >/dev/null
check "prefix boundary: specification.txt allowed" "$?" "false-positive block"
pipe_hook "$F" protect-references.sh "$(json_fp "src/main.c")" >/dev/null
check "normal source path allowed" "$?" "false-positive block"
F2="$(mkfixture protect-multi "$(printf '%s' "$MANIFEST_DEFAULT" | python3 -c 'import json,sys; m=json.load(sys.stdin); m["readonly_refs"]=[{"id":"spec","committed_path":"spec/"},{"id":"other","committed_path":"data"}]; print(json.dumps(m))')")"
pipe_hook "$F2" protect-references.sh "$(json_fp "spec/notes.txt")" >/dev/null; rc=$?
check "multi-ref: FIRST ref still enforced (CRLF regression)" "$([ "$rc" = "2" ] && echo 0 || echo 1)" "exit $rc"
pipe_hook "$F2" protect-references.sh "$(json_fp "data/x.csv")" >/dev/null; rc=$?
check "multi-ref: last ref enforced" "$([ "$rc" = "2" ] && echo 0 || echo 1)" "exit $rc"
F3="$(mkfixture protect-off "$(printf '%s' "$MANIFEST_DEFAULT" | python3 -c 'import json,sys; m=json.load(sys.stdin); m["modules"]["references"]=False; print(json.dumps(m))')")"
pipe_hook "$F3" protect-references.sh "$(json_fp "spec/notes.txt")" >/dev/null
check "modules.references=false -> escape hatch works" "$?" "blocked despite module off"

echo "== check-doc-freshness.sh =="
F="$(mkfixture docfresh)"
printf 'changed\n' >> "$F/src/main.c"
out="$(run_hook "$F" check-doc-freshness.sh)"
check "source changed, doc not -> nudge" "$(printf '%s' "$out" | grep -q 'README.md' && echo 0 || echo 1)" "no nudge: '$out'"
printf 'doc update\n' >> "$F/README.md"
out="$(run_hook "$F" check-doc-freshness.sh)"
check "doc also updated -> silent" "$([ -z "$out" ] && echo 0 || echo 1)" "unexpected nudge: '$out'"
# Session-awareness: a SOURCE-only change that is committed mid-session (clean
# worktree afterwards) must still nudge — the exemplar's Stop hooks were blind
# to exactly this. Fresh fixture so the doc isn't already dirty this session.
F3="$(mkfixture docfresh-commit)"
printf 'committed change\n' >> "$F3/src/main.c"
( cd "$F3" && git add -A >/dev/null 2>&1 && git commit -qm mid-session >/dev/null 2>&1 )
out="$(run_hook "$F3" check-doc-freshness.sh)"
check "sees mid-session COMMITS (clean worktree)" "$(printf '%s' "$out" | grep -q 'README.md' && echo 0 || echo 1)" "missed committed change: '$out'"
MULTI="$(printf '%s' "$MANIFEST_DEFAULT" | python3 -c 'import json,sys; m=json.load(sys.stdin); m["doc_map"]=[{"sources":["**"],"doc":"README.md"},{"sources":["src/**"],"doc":"README.md"}]; print(json.dumps(m))')"
F2="$(mkfixture docfresh-multi "$MULTI")"
out="$(run_hook "$F2" check-doc-freshness.sh)"
check "clean tree + broad glob -> silent (no .session pollution)" "$([ -z "$out" ] && echo 0 || echo 1)" "false nudge: '$out'"
printf 'x\n' >> "$F2/src/main.c"
out="$(run_hook "$F2" check-doc-freshness.sh)"
n="$(printf '%s' "$out" | grep -o 'README.md (mapped' | wc -l | tr -d ' ')"
check "duplicate doc rows -> listed once" "$([ "$n" = "1" ] && echo 0 || echo 1)" "listed $n times"
printf 'y\n' >> "$F2/README.md"
out="$(run_hook "$F2" check-doc-freshness.sh)"
check "multi-row doc_map + doc updated -> silent (CRLF regression)" "$([ -z "$out" ] && echo 0 || echo 1)" "false nudge: '$out'"

echo "== check-verify.sh =="
F="$(mkfixture verify)"
printf 'x\n' >> "$F/src/main.c"
out="$(run_hook "$F" check-verify.sh)"
check "source changed, no evidence -> nudge" "$(printf '%s' "$out" | grep -q 'run-tests.sh' && echo 0 || echo 1)" "no nudge"
printf 'ok\n' > "$F/test-report.txt"
out="$(run_hook "$F" check-verify.sh)"
check "fresh evidence -> silent" "$([ -z "$out" ] && echo 0 || echo 1)" "false nudge: '$out'"
rm "$F/src/main.c"
out="$(run_hook "$F" check-verify.sh)"
check "deleted source counts as change -> nudge" "$(printf '%s' "$out" | grep -q 'run-tests.sh' && echo 0 || echo 1)" "silent on deletion"
F2="$(mkfixture verify-md)"
printf 'doc\n' >> "$F2/src/notes.md"
out="$(run_hook "$F2" check-verify.sh)"
check "exempt pattern (**/*.md) -> silent" "$([ -z "$out" ] && echo 0 || echo 1)" "nudged on exempt file"
F3="$(mkfixture verify-auto "$(printf '%s' "$MANIFEST_DEFAULT" | python3 -c 'import json,sys; m=json.load(sys.stdin); m["verify"]["evidence"]="auto"; print(json.dumps(m))')")"
printf 'x\n' >> "$F3/src/main.c"
out="$(run_hook "$F3" check-verify.sh)"
check "evidence 'auto' -> dormant, silent" "$([ -z "$out" ] && echo 0 || echo 1)" "nudged while dormant"

echo "== regen-auto-regions.sh =="
F="$(mkfixture regen)"
printf 'a,b\n' > "$F/data/x.csv"
pipe_hook "$F" regen-auto-regions.sh "$(json_fp "data/x.csv")" >/dev/null
check "matching path runs generator" "$([ -f "$F/gen-ran.txt" ] && echo 0 || echo 1)" "generator did not run"
rm -f "$F/gen-ran.txt"
pipe_hook "$F" regen-auto-regions.sh "$(json_fp "$F/data/x.csv")" >/dev/null
check "absolute path runs generator" "$([ -f "$F/gen-ran.txt" ] && echo 0 || echo 1)" "abs-path strip failed"
rm -f "$F/gen-ran.txt"
pipe_hook "$F" regen-auto-regions.sh "$(json_fp "src/main.c")" >/dev/null
check "non-matching path -> no run" "$([ ! -f "$F/gen-ran.txt" ] && echo 0 || echo 1)" "ran on wrong path"
printf 'exit 1\n' > "$F/gen.sh"
pipe_hook "$F" regen-auto-regions.sh "$(json_fp "data/x.csv")" >/dev/null; rc=$?
check "failing generator never blocks (exit 0)" "$([ "$rc" = "0" ] && echo 0 || echo 1)" "exit $rc"
check "failing generator warns on stderr" "$(grep -q WARNING "$TMPROOT/stderr" && echo 0 || echo 1)" "no warning"

echo "== check-skill-cold-test.sh =="
F="$(mkfixture cold)"
mkdir -p "$F/.claude/skills/foo"; printf '# skill\n' > "$F/.claude/skills/foo/SKILL.md"
out="$(run_hook "$F" check-skill-cold-test.sh)"
check "new skill file -> nudge" "$(printf '%s' "$out" | grep -q 'foo/SKILL.md' && echo 0 || echo 1)" "no nudge"
( cd "$F" && git add -A >/dev/null && git commit -qm skill >/dev/null && git rev-parse HEAD > .claude/.session/start-ref )
printf 'l\nl\nl\nl\nl\nl\n' >> "$F/.claude/skills/foo/SKILL.md"
out="$(run_hook "$F" check-skill-cold-test.sh)"
check "6+ changed lines -> nudge" "$(printf '%s' "$out" | grep -q 'lines' && echo 0 || echo 1)" "no nudge"
( cd "$F" && git checkout -q -- .claude/skills/foo/SKILL.md )
printf 'l\nl\n' >> "$F/.claude/skills/foo/SKILL.md"
out="$(run_hook "$F" check-skill-cold-test.sh)"
check "2 changed lines -> silent" "$([ -z "$out" ] && echo 0 || echo 1)" "over-eager nudge"
( cd "$F" && git checkout -q -- .claude/skills/foo/SKILL.md )
printf '\xff\xfe#\x00s\x00' > "$F/.claude/skills/foo/SKILL.md"
out="$(run_hook "$F" check-skill-cold-test.sh)"
check "binary rewrite -> nudge (not silence)" "$(printf '%s' "$out" | grep -q 'binary' && echo 0 || echo 1)" "silent on total rewrite"

echo "== check-lesson-tagging.sh =="
F="$(mkfixture lesson)"
printf '# log\n\n## 2026-08-10 - x\n- scope: generic\n- applications: 2026-08-10\n' > "$F/.claude/learning-log.md"
out="$(run_hook "$F" check-lesson-tagging.sh)"
check "tagged untracked entry -> silent" "$([ -z "$out" ] && echo 0 || echo 1)" "false nudge: '$out'"
printf '\n## 2026-08-10 - y\n- rule: r\n' >> "$F/.claude/learning-log.md"
out="$(run_hook "$F" check-lesson-tagging.sh)"
check "untagged entry -> nudge" "$(printf '%s' "$out" | grep -q 'scope' && echo 0 || echo 1)" "no nudge"
D="$TMPROOT/unborn-log"; mkdir -p "$D/.claude"; ( cd "$D" && git init -q -b master && printf '## e\n- rule: r\n' > .claude/learning-log.md && git add -A >/dev/null )
out="$(run_hook "$D" check-lesson-tagging.sh)"
check "staged log + unborn HEAD -> nudge" "$(printf '%s' "$out" | grep -q 'scope' && echo 0 || echo 1)" "silent on unborn HEAD"

echo "== check-base-version.sh =="
F="$(mkfixture ver "$(printf '%s' "$MANIFEST_DEFAULT" | python3 -c 'import json,sys; m=json.load(sys.stdin); m["last_synced_version"]="0.0.0"; print(json.dumps(m))')")"
out="$(run_hook "$F" check-base-version.sh)"
check "behind plugin version -> nudge" "$(printf '%s' "$out" | grep -q '/base:sync' && echo 0 || echo 1)" "no nudge"
F2="$(mkfixture ver-ahead "$(printf '%s' "$MANIFEST_DEFAULT" | python3 -c 'import json,sys; m=json.load(sys.stdin); m["last_synced_version"]="9.9.9"; print(json.dumps(m))')")"
out="$(run_hook "$F2" check-base-version.sh)"
check "ahead of plugin -> silent" "$([ -z "$out" ] && echo 0 || echo 1)" "false nudge"

echo "== POSIX-path references (Windows) =="
# A reference bound from a Git Bash session records a POSIX path ("/tmp/spec",
# "/c/Users/me/spec"). Windows Python resolves those against the CURRENT DRIVE,
# so the guard silently matched nothing and the reference was unprotected —
# found by the end-to-end validation, 2026-08-11. Both spellings must guard.
POSIXREF="$TMPROOT/posixref"; mkdir -p "$POSIXREF"; printf 'spec\n' > "$POSIXREF/spec.txt"
POSIX_FORM="$(cygpath -u "$POSIXREF" 2>/dev/null || printf '%s' "$POSIXREF")"
F="$(mkfixture posixref-fixture "$(printf '%s' "$MANIFEST_DEFAULT" | python3 -c 'import json,sys; m=json.load(sys.stdin); m["readonly_refs"]=[{"id":"ext","committed_path":None,"local":True}]; print(json.dumps(m))')")"
python3 -c "import json,sys; json.dump({'ext': sys.argv[1]}, open(sys.argv[2],'w'))" "$POSIX_FORM" "$F/references.local.json"
pipe_hook "$F" protect-references.sh "$(json_fp "$POSIXREF/spec.txt")" >/dev/null; rc=$?
check "POSIX-bound ref blocks a native-path write" "$([ "$rc" = "2" ] && echo 0 || echo 1)" "exit $rc (ref stored as '$POSIX_FORM')"
pipe_hook "$F" protect-references.sh "$(json_fp "$POSIX_FORM/spec.txt")" >/dev/null; rc=$?
check "POSIX-bound ref blocks a POSIX-path write" "$([ "$rc" = "2" ] && echo 0 || echo 1)" "exit $rc"
if [ -n "${WINDIR:-}" ]; then
  out="$(CB_LIB="$LIB" python3 - <<'PY' 2>&1
import os, sys
sys.path.insert(0, os.environ["CB_LIB"])
import manifest as M
print(M.from_posix("/c/Users/x"))
PY
)"
  check "from_posix('/c/Users/x') -> drive form" "$([ "$out" = 'C:\Users\x' ] && echo 0 || echo 1)" "got '$out'"
fi

echo "== wiring & doc-consistency =="
# The suite drives hook scripts by filename, so a renamed/moved script would
# leave it green while silently unwiring the plugin (cold-test finding
# 2026-08-11). Validate hooks.json itself: it parses, and every command path
# it names resolves to a shipped file.
out="$(python3 - "$HOOKS/hooks.json" "$HOOKS" <<'PY'
import json, os, re, sys
hj, hooks_dir = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(hj, encoding="utf-8"))
except Exception as e:
    print(f"hooks.json does not parse: {e}"); sys.exit(0)
missing, wired = [], 0
for event, groups in d.get("hooks", {}).items():
    for g in groups:
        for h in g.get("hooks", []):
            wired += 1
            cmd = h.get("command", "")
            for m in re.findall(r'\$\{CLAUDE_PLUGIN_ROOT\}/hooks/([A-Za-z0-9_.-]+\.sh)', cmd):
                if not os.path.isfile(os.path.join(hooks_dir, m)):
                    missing.append(f"{event}:{m}")
if missing:
    print("wired but missing: " + ", ".join(missing))
elif wired == 0:
    print("no hooks wired at all")
PY
)"
check "hooks.json parses and every wired script exists" "$([ -z "$out" ] && echo 0 || echo 1)" "$out"

# Every shipped hook script must actually be wired (the reverse direction).
unwired=""
for f in "$HOOKS"/*.sh; do
  b="$(basename "$f")"
  grep -q "$b" "$HOOKS/hooks.json" || unwired="$unwired $b"
done
check "every shipped hook script is wired" "$([ -z "$unwired" ] && echo 0 || echo 1)" "unwired:$unwired"

# The commit-brevity prompt lives in two places (plugin hooks.json for Subs,
# Base's own settings.json because Base does not install its own plugin —
# DESIGN.md §7). Two homes are tolerable only if divergence is impossible to
# miss, so assert byte-equality here (cold-test DUPLICATE finding 2026-08-11).
out="$(python3 - "$HOOKS/hooks.json" "$REPO/.claude/settings.json" <<'PY'
import json, sys
def prompts(p):
    d = json.load(open(p, encoding="utf-8"))
    hooks = d.get("hooks", d)
    return [h.get("prompt") for groups in hooks.values() for g in groups
            for h in g.get("hooks", []) if h.get("type") == "prompt"]
a, b = prompts(sys.argv[1]), prompts(sys.argv[2])
if not a or not b:
    print(f"expected a prompt hook in both (plugin={len(a)}, base={len(b)})")
elif a[0] != b[0]:
    print("commit-brevity prompt text has diverged between plugin and Base settings")
PY
)"
check "commit-brevity prompt identical in plugin and Base settings" "$([ -z "$out" ] && echo 0 || echo 1)" "$out"

# The seeded settings.json must carry enabledPlugins as an object map: Claude
# Code rejects the whole file on the array form (seed <= 0.0.3 shipped the
# array; 3/3 Subs hit it, harvested 2026-11-22).
out="$(python3 -c '
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
ep = d.get("enabledPlugins")
if not isinstance(ep, dict):
    print("enabledPlugins is %s, expected an object" % type(ep).__name__)
elif ep.get("base@claudebase") is not True:
    print("enabledPlugins lacks base@claudebase: true")
' "$REPO/plugins/base/seed/.claude/settings.json.tmpl" 2>&1)"
check "seed settings.json: enabledPlugins is an object with base@claudebase" "$([ -z "$out" ] && echo 0 || echo 1)" "$out"

# Evidence dormancy sentinels: the interview offers the words "none yet", so
# they must silence check-verify exactly like "auto" does.
for sentinel in "auto" "none yet" "none"; do
  FS="$(mkfixture "verify-sentinel-$(printf '%s' "$sentinel" | tr ' ' '-')" "$(printf '%s' "$MANIFEST_DEFAULT" | python3 -c "import json,sys; m=json.load(sys.stdin); m['verify']['evidence']='$sentinel'; print(json.dumps(m))")")"
  printf 'x\n' >> "$FS/src/main.c"
  out="$(run_hook "$FS" check-verify.sh)"
  check "evidence '$sentinel' -> dormant" "$([ -z "$out" ] && echo 0 || echo 1)" "nudged: '$out'"
done

# Cold-test watches docs/ too, not just skills dirs.
F="$(mkfixture colddocs)"
mkdir -p "$F/docs"; printf '# design\n' > "$F/docs/DESIGN.md"
out="$(run_hook "$F" check-skill-cold-test.sh)"
check "new docs/*.md -> cold-test nudge" "$(printf '%s' "$out" | grep -q 'docs/DESIGN.md' && echo 0 || echo 1)" "no nudge: '$out'"

echo
printf 'RESULT: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -gt 0 ] && printf 'Failures:%s\n' "$FAILED_NAMES"
{ date -u '+%Y-%m-%dT%H:%M:%SZ'; printf 'passed=%d failed=%d\n' "$PASS" "$FAIL"; } > "$REPO/tests/last-run.txt"
[ "$FAIL" -eq 0 ]
