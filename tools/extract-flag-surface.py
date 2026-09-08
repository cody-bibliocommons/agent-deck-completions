#!/usr/bin/env python3
"""Print the parts of agent-deck's CLI surface that these completions encode.

    tools/extract-flag-surface.py <path-to-agent-deck-checkout>

Output is three sorted, diffable sections:

    [commands]        top-level commands, from the `switch args[0]` dispatch
    [tools]           built-in agent names, from builtinToolValues
    [<command path>]  one line per flag set, with each flag's type

Why parse the source instead of `--help`: agent-deck's help text is hand-written
per command and drifts from the flag sets the binary actually parses — several
real flags never appear in help, and some help output truncates. The flag-set
names double as command paths ("session start", "mcp server status"), which is
what makes this mapping exact.

`spec/flag-surface.txt` is the committed snapshot of this output. CI regenerates
it against upstream and diffs, so an upstream flag change shows up as a failure
instead of as silently stale completions. See AGENTS.md.
"""

import re
import sys
from pathlib import Path

FLAG_SET = re.compile(r'flag\.NewFlagSet\(\s*"([^"]*)"')
FLAG_DEF = re.compile(
    r'\b\w+\.(String|Bool|Int|Int64|Float64|Duration|Var)(?:Var)?\('
    r'\s*(?:&[\w.]+\s*,\s*)?"([\w\-.]+)"'
)
CASE_LABELS = re.compile(r'^\s*case\s+((?:"[^"]*"\s*,?\s*)+):')
TOOL_VALUES = re.compile(r'builtinToolValues\s*=\s*\[\]string\{([^}]*)\}', re.S)


def top_level_commands(main_go: Path) -> list[str]:
    """Command names from the `switch args[0]` dispatch, ignoring nested switches."""
    lines = main_go.read_text().splitlines()
    start = next(i for i, line in enumerate(lines) if 'switch args[0] {' in line)

    commands, depth = [], 0
    for line in lines[start + 1:]:
        if depth == 0:
            match = CASE_LABELS.match(line)
            if match:
                commands += re.findall(r'"([^"]*)"', match.group(1))
        depth += line.count('{') - line.count('}')
        if depth < 0:                      # closing brace of the switch itself
            break
    return sorted(set(commands))


def builtin_tools(settings_panel_go: Path) -> list[str]:
    match = TOOL_VALUES.search(settings_panel_go.read_text())
    if not match:
        return []
    return sorted(re.findall(r'"([^"]*)"', match.group(1)))


def flag_sets(cmd_dir: Path) -> dict[str, set[tuple[str, str]]]:
    """Map each flag-set name (a command path) to its (flag, type) pairs."""
    sets: dict[str, set[tuple[str, str]]] = {}
    for source in sorted(cmd_dir.glob('*.go')):
        if source.name.endswith('_test.go'):
            continue
        current = None
        for line in source.read_text().splitlines():
            named = FLAG_SET.search(line)
            if named:
                current = named.group(1)
                sets.setdefault(current, set())
                continue
            if current is None:
                continue
            for kind, flag in FLAG_DEF.findall(line):
                sets[current].add((flag, 'bool' if kind == 'Bool' else kind.lower()))
    return sets


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    checkout = Path(sys.argv[1])
    cmd_dir = checkout / 'cmd' / 'agent-deck'
    if not cmd_dir.is_dir():
        print(f'not an agent-deck checkout: {checkout}', file=sys.stderr)
        return 2

    print('[commands] ' + ' '.join(top_level_commands(cmd_dir / 'main.go')))
    print('[tools] ' + ' '.join(
        builtin_tools(checkout / 'internal' / 'ui' / 'settings_panel.go')))
    for name, flags in sorted(flag_sets(cmd_dir).items()):
        rendered = ' '.join(f'{flag}:{kind}' for flag, kind in sorted(flags))
        print(f'[{name}] {rendered}'.rstrip())
    return 0


if __name__ == '__main__':
    sys.exit(main())
