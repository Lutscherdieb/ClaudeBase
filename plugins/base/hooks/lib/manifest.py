#!/usr/bin/env python3
"""manifest.py — the ONE parser for .claude/base-manifest.json, used by every
ClaudeBase hook that needs structured data, AND the one home of path matching
(readonly-ref checks, generator glob matching). Path comparison in bash string
patterns was tried first and fixture-tested full of bypasses (case, 8.3 short
names, dot-segments, trailing slashes — 2026-08-10 test run); canonicalizing
here with os.path.realpath/normcase removed the whole class. Doctrine: prefer
removing the choice over documenting the hazard.

Implements the manifest-field contract in docs/DESIGN.md section 3 and the
one-parser rule in section 5 - change a field's meaning here and that table
changes in the same edit.

Why a single python3 parser instead of jq-with-fallbacks: dual implementations
of the same query drift silently. Degradation is honest instead: no python3 on
the machine -> hooks that need structure exit 0 silently, and /base:repo-setup's
preflight + /base:doctor name the missing tool and which hooks are dormant.

stdout is reconfigured to UTF-8 with LF newlines: Windows CPython otherwise
emits \r\n, and Git Bash $() strips only the FINAL \r\n — every earlier line
kept a trailing \r, silently breaking every multi-line consumer (fixture-caught
2026-08-10: protect-references enforced only its LAST ref; doc-freshness
false-nudged on any multi-row doc_map). cb_manifest_query also strips \r as a
second belt for this blocking-hook-feeding path.

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
  check-readonly <path>    -> ids of readonly refs whose canonical path is a
                              prefix of <path>'s canonical form; empty = allowed
  match-generators <path>  -> generator commands whose trigger_globs match
                              <path> (canonicalized repo-relative), deduped
"""
import json
import os
import re
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", newline="\n")
except AttributeError:
    pass

WINDOWS = os.name == "nt"


def norm(p):
    """Normalize a path string for output/matching: forward slashes, no
    doubled slashes, no leading './', no trailing slash (dirs and their
    contents must prefix-match — fixture bug: 'spec/' never matched
    'spec/notes.txt')."""
    p = (p or "").replace("\\", "/")
    while "//" in p:
        p = p.replace("//", "/")
    while p.startswith("./"):
        p = p[2:]
    if len(p) > 1 and p.endswith("/") and not p.endswith(":/"):
        p = p.rstrip("/")
    return p


def canon(p, root):
    """Canonical absolute form for comparison: absolute (joined to root if
    relative), realpath (resolves 8.3 short names, symlinks, dot-segments,
    and on-disk case for existing prefixes), then case-folded on Windows."""
    p = (p or "").replace("/", os.sep).replace("\\", os.sep)
    if not os.path.isabs(p):
        p = os.path.join(root, p)
    p = os.path.realpath(p)
    return os.path.normcase(p) if WINDOWS else p


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
    g, p = norm(glob), norm(path)
    if WINDOWS:
        g, p = g.lower(), p.lower()
    return bool(glob_to_regex(g).match(p))


def readonly_pairs(m, root):
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
            yield rid, norm(p)


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
        # Dormancy sentinels: anything that means "no evidence artifact yet"
        # prints empty so check-verify stays quiet. "none yet" is included
        # because the interview offers exactly those words (cold-test finding
        # 2026-08-11: a Sub answering "none yet" would otherwise treat it as a
        # real path and nudge on every Stop forever).
        print("" if ev.strip().lower() in ("auto", "none", "none yet", "n/a") else norm(ev))
    elif sub == "readonly-paths":
        for rid, p in readonly_pairs(m, root):
            print(f"{rid}\t{p}")
    elif sub == "check-readonly":
        if len(sys.argv) < 4:
            return 4
        target = canon(sys.argv[3], root)
        for rid, p in readonly_pairs(m, root):
            cref = canon(p, root)
            if target == cref or target.startswith(cref + os.sep):
                print(rid)
    elif sub == "match-generators":
        if len(sys.argv) < 4:
            return 4
        # Canonicalize, then relativize against the repo root so absolute
        # inputs in any spelling (case, 8.3, dot-segments) match repo-relative
        # trigger globs (fixture bugs Edge B/C/G, 2026-08-10).
        target = canon(sys.argv[3], root)
        croot = canon(root, root)
        if target == croot or target.startswith(croot + os.sep):
            rel = os.path.relpath(target, croot).replace(os.sep, "/")
        else:
            rel = norm(sys.argv[3])
        seen = []
        for gen in m.get("generators", []):
            cmd = gen.get("command", "")
            if not cmd or cmd in seen:
                continue
            if any(matches(g, rel) for g in gen.get("trigger_globs", [])):
                seen.append(cmd)
                print(cmd)
    else:
        return 4
    return 0


if __name__ == "__main__":
    sys.exit(main())
