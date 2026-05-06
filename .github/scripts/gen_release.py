#!/usr/bin/env python3
"""Generate release_notes.md and README.txt for a dotfiles release.

Environment variables (all required unless noted):
  CURRENT     current tag name          e.g. v0.0.2
  PREVIOUS    previous tag name         e.g. v0.0.1  (empty for initial release)
  DATE        release date (YYYY-MM-DD) e.g. 2025-05-06
  REPO        GitHub repo slug          e.g. hsuyelin/dotfiles
  PATCH_FILE  patch filename            e.g. v0.0.1-to-v0.0.2.patch (empty if none)
"""

import os
import re
import subprocess
import sys
from collections import defaultdict

# ── Section ordering ──────────────────────────────────────────────────────────

SECTION_ORDER = [
    "Features",
    "Bug Fixes",
    "Performance",
    "Refactor",
    "Documentation",
    "Tests",
    "Build",
    "CI",
    "Chore",
    "Reverts",
    "Other",
]

TYPE_MAP: dict[str, str] = {
    "feat":     "Features",
    "feature":  "Features",
    "fix":      "Bug Fixes",
    "bugfix":   "Bug Fixes",
    "hotfix":   "Bug Fixes",
    "perf":     "Performance",
    "refactor": "Refactor",
    "docs":     "Documentation",
    "doc":      "Documentation",
    "test":     "Tests",
    "tests":    "Tests",
    "build":    "Build",
    "ci":       "CI",
    "chore":    "Chore",
    "style":    "Chore",
    "revert":   "Reverts",
}

# ── Git ───────────────────────────────────────────────────────────────────────

def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args], capture_output=True, text=True, check=True
    )
    return result.stdout


def get_commits(prev: str, current: str) -> list[dict]:
    """Return list of {hash, subject, body} dicts."""
    ref = f"{prev}..{current}" if prev else current
    # US (\x1f) separates fields; RS (\x1e) separates records
    raw = git(
        "log", ref,
        "--format=%H\x1f%s\x1f%b\x1e",
        "--no-merges",
    )
    commits: list[dict] = []
    for record in raw.split("\x1e"):
        record = record.strip()
        if not record:
            continue
        parts = record.split("\x1f", 2)
        commits.append({
            "hash":    parts[0].strip(),
            "subject": parts[1].strip() if len(parts) > 1 else "",
            "body":    parts[2].strip() if len(parts) > 2 else "",
        })
    return [c for c in commits if c["subject"]]


# ── Commit parsing ────────────────────────────────────────────────────────────

CONV_RE = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[^)]+)\))?(?P<bang>!)?:\s*(?P<msg>.+)$",
    re.IGNORECASE,
)


def parse_commit(c: dict) -> dict:
    m = CONV_RE.match(c["subject"])
    if m:
        ctype    = m.group("type").lower()
        scope    = m.group("scope") or ""
        msg      = m.group("msg").strip()
        breaking = m.group("bang") == "!"
    else:
        ctype    = "other"
        scope    = ""
        msg      = c["subject"]
        breaking = False

    bc_detail = ""
    bc_match  = re.search(r"BREAKING CHANGE:\s*(.+)", c["body"], re.IGNORECASE)
    if bc_match:
        breaking  = True
        bc_detail = bc_match.group(1).strip().splitlines()[0]

    return {
        **c,
        "type":        ctype,
        "scope":       scope,
        "msg":         msg,
        "section":     TYPE_MAP.get(ctype, "Other"),
        "is_breaking": breaking,
        "bc_detail":   bc_detail or msg,
    }


# ── Release notes (Markdown) ──────────────────────────────────────────────────

def build_release_notes(parsed: list[dict], is_first: bool) -> str:
    sections: dict[str, list[str]] = defaultdict(list)
    breaking: list[str] = []

    for p in parsed:
        entry = (
            f"- **{p['scope']}**: {p['msg']}"
            if p["scope"] else
            f"- {p['msg']}"
        )
        sections[p["section"]].append(entry)
        if p["is_breaking"]:
            breaking.append(f"- {p['bc_detail']}")

    lines: list[str] = []

    for sec in SECTION_ORDER:
        items = sections.get(sec)
        if not items:
            continue
        lines += [f"### {sec}", *items, ""]

    if breaking:
        lines += [
            "> [!IMPORTANT]",
            "> **Breaking Changes**",
            *[f"> {b}" for b in breaking],
            "",
        ]

    if is_first:
        lines += [
            "> [!NOTE]",
            "> Initial release — no upgrade patch available.",
            "> Install via `git clone https://github.com/$REPO ~/.config && bash install.sh`.",
            "",
        ]

    return "\n".join(lines).rstrip("\n")


# ── README.txt (plain text) ───────────────────────────────────────────────────

def build_readme(
    current: str,
    prev: str,
    date: str,
    repo: str,
    patch_file: str,
) -> str:
    title     = f"{current}  ({date})"
    separator = "=" * len(title)

    lines = [
        title,
        separator,
        "",
        "INSTALL (fresh machine)",
        "------------------------",
        f"  git clone https://github.com/{repo} ~/.config",
        "  cd ~/.config && bash install.sh",
        "",
    ]

    if patch_file and prev:
        patch_header = f"PATCH INSTALL  ({prev} → {current})"
        lines += [
            patch_header,
            "-" * len(patch_header),
            "  Prerequisites: git 2.x",
            "",
            "  1. Verify the patch is intact:",
            "       sha512sum -c sha512sum.txt",
            "",
            "  2. Dry-run (no changes applied):",
            f"       git -C ~/.config apply --check {patch_file}",
            "",
            "  3. Apply:",
            f"       git -C ~/.config apply {patch_file}",
            "",
            "  If the patch fails due to local modifications, resolve conflicts",
            "  manually or perform a fresh clone instead.",
            "",
        ]
    else:
        lines += [
            "NOTE",
            "----",
            "  This is the initial release — no upgrade patch is available.",
            "",
        ]

    lines += [
        "CHECKSUMS",
        "---------",
        "  Verify the downloaded source archives against sha512sum.txt:",
        "    sha512sum -c sha512sum.txt",
        f"  Covers: {current}.tar.gz, {current}.zip",
        "",
        "VERSION",
        "-------",
        f"  This release:  {current}",
    ]
    if prev:
        lines.append(f"  Previous:      {prev}")
    lines.append(f"  Released:      {date}")
    lines.append("")

    return "\n".join(lines)


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    current    = os.environ["CURRENT"]
    prev       = os.environ.get("PREVIOUS", "")
    date       = os.environ["DATE"]
    repo       = os.environ["REPO"]
    patch_file = os.environ.get("PATCH_FILE", "")
    is_first   = not bool(prev)

    commits = get_commits(prev, current)
    if not commits:
        print("WARNING: no commits found in range", file=sys.stderr)

    parsed = [parse_commit(c) for c in commits]

    notes  = build_release_notes(parsed, is_first)
    readme = build_readme(current, prev, date, repo, patch_file)

    with open("release_notes.md", "w", encoding="utf-8") as f:
        f.write(notes)

    with open("README.txt", "w", encoding="utf-8") as f:
        f.write(readme)

    print(f"  release_notes.md  {len(notes):>6,} chars")
    print(f"  README.txt        {len(readme):>6,} chars")


if __name__ == "__main__":
    main()
