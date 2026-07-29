#!/usr/bin/env python3
"""Assert both completions cover every flag in spec/flag-surface.txt.

    tools/check-coverage.py

The two completion files necessarily duplicate the option lists (different
syntaxes), so the standing hazard is adding an upstream flag to one and
forgetting the other. This compares the snapshot's flag names against both files
and fails on anything missing from either.

It is deliberately a coarse whole-file search: mapping every flag to the exact
completion context it belongs in would re-implement both files' dispatch. This
catches the failure that actually happens, and `tests/run.{bash,zsh}` cover
behaviour.

OMITTED lists flags that are intentionally absent, with the reason.
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# Flags of commands the completions deliberately do not offer at all: internal
# plumbing (hook-handler, codex-notify, notify-daemon, run-task, mcp-proxy,
# creds-refresh) and the interactive `feedback` prompt.
OMITTED = {
    'config-dir': 'creds-refresh, internal',
    'endpoint': 'creds-refresh, internal',
    'interval': 'creds-refresh/watcher-internal',
    'once': 'creds-refresh + notify-daemon, internal',
    'threshold': 'creds-refresh, internal',
    'child': 'run-task, internal',
    'foo': 'test-only flag in main.go',
}


def snapshot_flags(surface: Path) -> set[str]:
    flags: set[str] = set()
    for line in surface.read_text().splitlines():
        if line.startswith(('[commands]', '[tools]')):
            continue
        _, _, rendered = line.partition('] ')
        for entry in rendered.split():
            flags.add(entry.rsplit(':', 1)[0])
    return flags


def main() -> int:
    flags = snapshot_flags(REPO / 'spec' / 'flag-surface.txt')
    files = {
        'bash': (REPO / 'bash' / 'agent-deck.bash').read_text(),
        'zsh': (REPO / 'zsh' / '_agent-deck').read_text(),
    }

    missing: dict[str, list[str]] = {shell: [] for shell in files}
    for flag in sorted(flags):
        if flag in OMITTED:
            continue
        # Single letters are short options (-q); everything else is long (--json).
        pattern = (rf'(?<![\w-]){re.escape("-" + flag)}(?![\w-])' if len(flag) == 1
                   else rf'(?<![\w-]){re.escape("--" + flag)}(?![\w-])')
        for shell, text in files.items():
            if not re.search(pattern, text):
                missing[shell].append(flag)

    for shell, absent in missing.items():
        for flag in absent:
            print(f'MISSING in {shell}: {flag}')

    total = sum(len(absent) for absent in missing.values())
    omitted_here = flags & set(OMITTED)
    checked = len(flags) - len(omitted_here)
    print(f'\n{checked} flags checked against both completions, {total} missing')
    if omitted_here:
        print(f'{len(omitted_here)} intentionally omitted: '
              + ', '.join(sorted(omitted_here)))
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())
