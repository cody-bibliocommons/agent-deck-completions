#!/usr/bin/env python3
"""Assert both completions cover every flag and tool in spec/flag-surface.txt.

    tools/check-coverage.py

The two completion files necessarily duplicate the option lists (different
syntaxes), so the standing hazard is adding an upstream flag to one and
forgetting the other. This compares the snapshot's flag names against both files
and fails on anything missing from either.

It is deliberately a coarse whole-file search: mapping every flag to the exact
completion context it belongs in would re-implement both files' dispatch. This
catches the failure that actually happens, and `tests/run.{bash,zsh}` cover
behaviour.

OMITTED lists flags that are intentionally absent, and EXTRA_TOOLS the agent
names the completions offer beyond upstream's, both with reasons.
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
    'child': 'run-task, internal',
    'foo': 'test-only flag in main.go',
}


# Tool names the completions offer that upstream's builtinToolValues does not.
# `--cmd` takes an arbitrary command, so an extra name here can never be invalid
# — but it must be deliberate, and this is where that is recorded.
EXTRA_TOOLS = {
    'shell': 'a plain shell is a valid --cmd but is not a builtin tool value',
    'kiro-cli': "upstream's feat/kiro-cli-tool branch, not yet on main",
}


def snapshot_tools(surface: Path) -> set[str]:
    for line in surface.read_text().splitlines():
        if line.startswith('[tools] '):
            return set(line.removeprefix('[tools] ').split())
    return set()


def completion_tools(files: dict[str, str]) -> dict[str, set[str]]:
    """The tool names each completion offers for -c/--cmd."""
    bash = set(re.search(r"__agent_deck_tools='([^']*)'", files['bash']).group(1).split())
    zsh_body = re.search(r'__agent_deck_tools\(\) \{(.*?)^\}',
                         files['zsh'], re.S | re.M).group(1)
    zsh = set(re.findall(r"^\s*'([\w.-]+):", zsh_body, re.M))
    return {'bash': bash, 'zsh': zsh}


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

    upstream_tools = snapshot_tools(REPO / 'spec' / 'flag-surface.txt')
    for shell, offered in completion_tools(files).items():
        for tool in sorted(upstream_tools - offered):
            print(f'MISSING tool in {shell}: {tool}')
            total += 1
        for tool in sorted(offered - upstream_tools - set(EXTRA_TOOLS)):
            print(f'UNDECLARED extra tool in {shell}: {tool} '
                  f'(add it to EXTRA_TOOLS with a reason, or remove it)')
            total += 1

    omitted_here = flags & set(OMITTED)
    checked = len(flags) - len(omitted_here)
    print(f'\n{checked} flags checked against both completions, {total} missing')
    print(f'{len(upstream_tools)} upstream tools checked, '
          f'{len(EXTRA_TOOLS)} declared extras: ' + ', '.join(sorted(EXTRA_TOOLS)))
    if omitted_here:
        print(f'{len(omitted_here)} intentionally omitted flags: '
              + ', '.join(sorted(omitted_here)))
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())
