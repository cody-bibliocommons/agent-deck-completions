#!/usr/bin/env python3
"""Assert every agent-deck version reference matches spec/agent-deck-version.txt.

    tools/check-version-refs.py

The agent-deck release these completions describe is stated in five places: the
`Generated against` header of each completion file, the README's provenance
sentence, and twice in AGENTS.md. All five are prose, so they rot independently.
That has already happened once: a drift fix bumped AGENTS.md's provenance line
and left the other four claiming the previous release, including the two headers
that ship to users.

`spec/agent-deck-version.txt` is the single source. This walks every tracked text
file and fails on any `vX.Y.Z` that disagrees with it. Every such string in this
repo is an agent-deck version, so a blunt "no other version may appear" is both
simpler and stricter than one pattern per site, and it catches a new claim added
in a file this script has never heard of.

`vX` and `vX.Y` are left alone: `actions/checkout@v4` and `bash-completion v2`
are not version claims about agent-deck.
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VERSION_FILE = REPO / 'spec' / 'agent-deck-version.txt'

SEMVER = re.compile(r'v[0-9]+\.[0-9]+\.[0-9]+')
VALID_VERSION = re.compile(r'^v[0-9]+\.[0-9]+\.[0-9]+$')

# `.claude` holds git worktrees, which are whole second copies of this repo:
# scanning them would report every finding twice, against the wrong paths.
SKIP_DIRS = {'.git', '.claude'}


def declared_version() -> str:
    version = VERSION_FILE.read_text().strip()
    if not VALID_VERSION.match(version):
        sys.exit(f'{VERSION_FILE.relative_to(REPO)} is not a vX.Y.Z version: {version!r}')
    return version


def scannable_files() -> list[Path]:
    files = []
    for path in sorted(REPO.rglob('*')):
        if not path.is_file() or path == VERSION_FILE:
            continue
        if SKIP_DIRS.intersection(path.relative_to(REPO).parts):
            continue
        files.append(path)
    return files


def main() -> int:
    version = declared_version()

    wrong: list[tuple[Path, int, str, str]] = []
    checked = 0
    for path in scannable_files():
        try:
            text = path.read_text()
        except (UnicodeDecodeError, OSError):
            continue          # binary or unreadable; no version claim to make
        checked += 1
        for number, line in enumerate(text.splitlines(), start=1):
            for found in SEMVER.findall(line):
                if found != version:
                    wrong.append((path.relative_to(REPO), number, found, line.strip()))

    for path, number, found, line in wrong:
        print(f'STALE in {path}:{number}: says {found}, expected {version}')
        print(f'    {line}')

    print(f'\n{checked} files scanned against {VERSION_FILE.relative_to(REPO)} '
          f'({version}), {len(wrong)} stale')
    return 1 if wrong else 0


if __name__ == '__main__':
    sys.exit(main())
