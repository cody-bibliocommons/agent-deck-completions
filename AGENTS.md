# AGENTS.md — context for LLM agents working on this repo

Read this before editing either completion file. It records **what these files
are, how their contents were derived, and which non-obvious constraints will
break them if you "clean them up"**.

## What this repo is

Two hand-maintained shell completion scripts for the third-party CLI
[`agent-deck`](https://github.com/asheshgoplani/agent-deck):

- `zsh/_agent-deck` — zsh, `#compdef` style, `_arguments`-based, ~1120 lines
- `bash/agent-deck.bash` — bash, single `_agent_deck` function, ~470 lines

They are installed by symlink (`install.sh`), so the repo is the single source of
truth: a `git pull` updates the live completions with no reinstall.

This repo does **not** vendor or build agent-deck. It only describes its CLI.

## Why the contents are trustworthy (and how to keep them that way)

The command and option lists were **not** transcribed from `--help` output.
They were extracted from the upstream Go source, because `--help` text in this
CLI is hand-written per command and drifts from the actual `flag.FlagSet`
registrations (several real flags never appear in help, and help truncates).

The extraction: for each non-test file in `cmd/agent-deck/`, find every
`flag.NewFlagSet("<name>", …)` and attribute all following
`fs.String/Bool/Int/Duration/Var(...)` calls to that flag-set name. The flag-set
names are conveniently the command paths themselves (`"session start"`,
`"group reorder"`, `"mcp server status"`), which yields an exact
command-path → options map:

```python
# run inside a checkout of agent-deck, in cmd/agent-deck/
import re, glob
pat  = re.compile(r'flag\.NewFlagSet\(\s*"([^"]*)"')
flag = re.compile(r'\b\w+\.(String|Bool|Int|Int64|Float64|Duration|Var)(?:Var)?\(\s*(?:&\w+\s*,\s*)?"([\w\-\.]+)"')
out, cur = {}, None
for f in sorted(x for x in glob.glob('*.go') if not x.endswith('_test.go')):
    for ln in open(f):
        m = pat.search(ln)
        if m: cur = m.group(1); out.setdefault(cur, set()); continue
        if cur:
            for kind, name in flag.findall(ln):
                out[cur].add((name, 'bool' if kind == 'Bool' else kind.lower()))
for k in sorted(out):
    print(f"[{k}] " + " ".join(f"{n}:{t}" for n, t in sorted(out[k])))
```

Top-level commands come from the `switch` on `args[0]` in
`cmd/agent-deck/main.go`; per-group subcommands and their aliases come from the
`case "…":` lists in `session_cmd.go`, `mcp_cmd.go`, `skill_cmd.go`,
`group_cmd.go`, `remote_cmd.go`, `worktree_cmd.go`, `conductor_cmd.go`,
`fleet_cmd.go`, `plugin_cmd.go`, `costs_cmd.go`, `watcher_cmd.go`,
`openclaw_cmd.go`, `hook_handler.go`. The tool list (`claude`, `codex`, …,
`kiro-cli`) comes from `builtinToolValues` in `internal/ui/settings_panel.go`.

**To update after an upstream release:** re-run the snippet above against the new
checkout, diff it against the previous output, and apply only the deltas. That is
how `kiro-cli` was added. Do not rewrite the completions from `--help`.

Verified against agent-deck **v1.10.11**; the flag surface was identical between
the v1.10.11 tag and a later `main` (only the tool list had changed).

## Dynamic completion contract

Both scripts shell out to the real binary for live values. Every source used is
a `--json` subcommand that is fast (all measured at ~0.00s, so nothing is
cached) and read-only.

The extractor is deliberately a `grep -o '"key"…"value"'` + `sed` pair rather
than `jq`, for three reasons:

1. `jq` is not guaranteed to be installed, and a completion must never error.
2. It works on both shapes agent-deck emits — pretty-printed
   `json.MarshalIndent` (one field per line) *and* the compact single-line form
   used by `try --list --json`.
3. When a list is empty, several subcommands print a **plain sentence** instead
   of JSON (`list --json` prints `No sessions found in profile 'default'.`).
   A grep-based reader yields nothing; a JSON parser would error.

Every one of those payloads exposes the value under `"name"`, except: sessions
use `"id"`/`"title"`/`"status"` (parsed pairwise with `awk`, flushing on
`"status"` because it is the first non-`omitempty` field after both), and groups
use `"path"` (the full nested group path, which is what the CLI accepts).

### Profile scoping

`-p/--profile` given before the subcommand must be forwarded to every data
lookup, or completions silently list the wrong profile's objects. Both scripts
scan the words *before the first positional* and stop there, because `-p` is
overloaded:

| Context | `-p` means |
|---|---|
| before any subcommand | `--profile` |
| `add`, `launch` | `--parent` |
| `group reorder` | `--position` |

In zsh this is `__agent_deck_scan_gopts`, called at the top of `_agent-deck`
*before* `_arguments`. It cannot be derived from `opt_args` instead: when the
user is completing the value of `-g`, `_arguments` has not returned yet, so
`opt_args` is empty and group completion would query the default profile. This
was a real bug found in testing; do not "simplify" it back.

## Gotchas that will bite you

1. **`status` is a read-only variable in zsh** (it aliases `$?`). `local status`
   inside a completion function aborts it with
   `read-only variable: status`. The session parser uses `sstate`.
2. **zsh needs a real terminal to complete.** `tests/comptest.zsh` uses
   `zsh/zpty`. `PS1` passed to `zpty` must contain no spaces and no `>` — zpty
   parses its own argv and a redirect character makes it fail with
   `parse error near '>'`.
3. **bash keeps an escaped word whole.** `foo Comp\ Test <TAB>` gives
   `COMP_WORDS=(foo 'Comp\ Test' '')` — verified against a real interactive bash
   with a probe completion, not assumed. So counting positional words is safe,
   and `tests/comptest.bash` reproduces that splitting (it `eval`s the line and
   re-escapes with `printf %q`) instead of a naive `read -a`.
4. **Spaces in session titles.** bash candidates are emitted `printf %q`-escaped
   and `$cur` is stripped of backslashes before prefix-matching, so a half-typed
   `Comp\ Te` still matches `Comp Test`. Don't switch to a bare
   `compgen -W "$list"`; it word-splits multi-word candidates.
5. **Colons in zsh `_describe` values** must be escaped (`${val//:/\\:}`) or the
   description parsing eats them — session titles can contain colons.
6. **`--heartbeat` has two arities** — duration under `session children`,
   boolean under `conductor setup`. `__agent_deck_opt_takes_value` resolves it
   against `${pos[0]}`. If you add another ambiguous flag, extend that function
   rather than the flat list.
7. **Free-text options return no candidates on purpose.** In bash,
   `__agent_deck_option_value` returns 0 with an empty `COMPREPLY` for
   value-taking options with no meaningful completer, which suppresses bash's
   default filename fallback. Returning non-zero there would offer files for
   `--title`.
8. **Internal plumbing commands are intentionally omitted** from the command
   list: `hook-handler`, `codex-notify`, `notify-daemon`, `run-task`,
   `mcp-proxy`, `creds-refresh`. They exist in `main.go`'s switch but are not
   for humans. Don't "fix" the missing entries.

## Verification procedure

Structural checks (fast, run always):

```bash
zsh -n zsh/_agent-deck
bash -n bash/agent-deck.bash
```

Behavioural checks — these are the ones that catch real breakage:

```bash
tests/comptest.zsh  'agent-deck '                       # top-level commands
tests/comptest.zsh  'agent-deck session '               # nested subcommands
tests/comptest.zsh  'agent-deck add -c '                # enum values
tests/comptest.zsh  'agent-deck -p <profile> session start '   # profile-scoped dynamic
tests/comptest.bash 'agent-deck fleet recover --'       # option list
tests/comptest.bash 'agent-deck -p <profile> group move Comp\ Test '  # positional past an escaped arg
```

To exercise session-dependent paths without touching the user's real sessions,
create a throwaway profile — `agent-deck add` only writes a registry entry, it
does not start tmux:

```bash
agent-deck -p _tmptest add -t "Comp Test" -c claude /tmp
# … run tests …
agent-deck -p _tmptest remove "Comp Test"
printf 'y\n' | agent-deck profile delete _tmptest
```

Confirm a real-shell install with
`zsh -ic 'print -r -- ${_comps[agent-deck]}'` (expect `_agent-deck`) and
`bash -ic 'complete -p agent-deck'` (expect `complete -F _agent_deck agent-deck`).

## Design notes

- **zsh** uses `_arguments -C` with `'1:command:…'` + `'*:: :->args'` and
  dispatches on `${words[1]}`, one `__agent_deck_<cmd>` function per command
  group, each repeating the pattern for its own subcommands. Aliases are listed
  as separate `_describe` entries with identical descriptions, which makes zsh
  collapse them into one row (`list  ls  -- list all sessions`).
- **bash** cannot nest that way, so it computes the positional word list once
  (skipping options and their values) and switches on
  `${pos[0]}`/`${pos[1]}`/`${pos[2]}` with `${#pos[@]}` as the argument index.
  `${#pos[@]}` counts positionals strictly *before* the word being completed, so
  `== 1` means "completing the first argument of the command".
- Option *lists* are duplicated between the two files by necessity (different
  syntaxes). When you add a flag, add it in both, and keep the descriptions in
  the zsh file in sync with the README table.
