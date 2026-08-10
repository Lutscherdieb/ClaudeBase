#!/usr/bin/env python3
"""manifest.py — the ONE parser for .claude/base-manifest.json, used by every
ClaudeBase hook that needs structured data.

Why a single python3 parser instead of jq-with-fallbacks: dual implementations
of the same query drift silently (exemplar doctrine: prefer removing the choice
over documenting the hazard). Degradation is honest instead: no python3 on the
machine -> hooks that need structure exit 0 silently, and /base:repo-setup's
preflight + /base:doctor name the missing tool and which hooks are dormant.

Usage: manifest.py <repo_root> <subcommand> [args]
Exit codes: 0 ok, 3 manifest missing/unreadable, 4 bad usage.

Subcommands (line-oriented output, tab-separated where noted):
  module <name>            -> "true"/"false" (missing modules key -> true)
  last-synced              -> the last_synced_version string
  doc-map                  -> "<glob>\t<doc>" per source-glob x doc pair
  source-specs             -> source_globs, one per line
  exempt                   -> verify.exempt_patterns, one per line
  verify-command           -> verify.command or empty
  verify-evidence          -> verify.evidence path or empty ("auto" -> empty)
  readonly-paths           -> "<id>\t<path>" per resolvable readonly ref
                              (committed_path, else references.local.json)
  match-generators <path>  -> generator commands whose trigger_globs match
                              <path> (repo-relative, forward slashes), deduped
"""
import json
import os
import re
import sys


def norm(p):
    p = (p or "").replace("\\", "/")
    while "//" in p:
        p = p.replace("//", "/")
    return p


def glob_to_regex(glob):
    """Translate a doc-map/generator glob to a regex over repo-relative
    forward-slash paths. ** crosses directory separators, * and ? do not."""
    out = []
    i = 0
    while i < len(glob):
        c = glob[i]
        if c == "*":
            if glob[i : i + 3] == "**/":
                out.append(r"(?:.*/)?")
                i += 3
                continue
            if glob[i : i + 2] == "**":
                out.append(r".*")
                i += 2
                continue
            out.append(r"[^/]*")
        elif c == "?":
            out.append(r"[^/]")
        else:
            out.append(re.escape(c))
        i += 1
    return re.compile("^" + "".join(out) + "$")


def matches(glob, path):
    return bool(glob_to_regex(norm(glob)).match(norm(path)))


def main():
    if len(sys.argv) < 3:
        return 4
    root, sub = sys.argv[1], sys.argv[2]
    mpath = os.path.join(root, ".claude", "base-manifest.json")
    try:
        with open(mpath, encoding="utf-8") as f:
            m = json.load(f)
    except (OSError, ValueError):
        return 3

    if sub == "module":
        if len(sys.argv) < 4:
            return 4
        v = m.get("modules", {}).get(sys.argv[3], True)
        print("true" if v else "false")
    elif sub == "last-synced":
        print(m.get("last_synced_version", ""))
    elif sub == "doc-map":
        for row in m.get("doc_map", []):
            doc = row.get("doc", "")
            for g in row.get("sources", []):
                if g and doc:
                    print(f"{norm(g)}\t{norm(doc)}")
    elif sub == "source-specs":
        for g in m.get("source_globs", []):
            if g:
                print(norm(g))
    elif sub == "exempt":
        for g in (m.get("verify", {}) or {}).get("exempt_patterns", []):
            if g:
                print(norm(g))
    elif sub == "verify-command":
        print((m.get("verify", {}) or {}).get("command") or "")
    elif sub == "verify-evidence":
        ev = (m.get("verify", {}) or {}).get("evidence") or ""
        print("" if ev == "auto" else norm(ev))
    elif sub == "readonly-paths":
        local = {}
        lpath = os.path.join(root, "references.local.json")
        try:
            with open(lpath, encoding="utf-8") as f:
                local = json.load(f)
        except (OSError, ValueError):
            pass
        for ref in m.get("readonly_refs", []):
            rid = ref.get("id", "")
            p = ref.get("committed_path") or local.get(rid) or ""
            if rid and p:
                print(f"{rid}\t{norm(p)}")
    elif sub == "match-generators":
        if len(sys.argv) < 4:
            return 4
        path = norm(sys.argv[3])
        seen = []
        for gen in m.get("generators", []):
            cmd = gen.get("command", "")
            if not cmd or cmd in seen:
                continue
            if any(matches(g, path) for g in gen.get("trigger_globs", [])):
                seen.append(cmd)
                print(cmd)
    else:
        return 4
    return 0


if __name__ == "__main__":
    sys.exit(main())
