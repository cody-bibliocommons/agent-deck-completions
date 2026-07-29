# AGENTS.md — context for LLM agents working on this repo

Read this before editing either completion file. It records **what these files
are, how their contents were derived, and which non-obvious constraints will
break them if you "clean them up"**.

## What this repo is

Two hand-maintained shell completion scripts for the third-party CLI
[`agent-deck`](https://github.com/asheshgoplani/agent-deck):

- `zsh/_agent-deck` — zsh, `#compdef` style, `_arguments`-based, ~1110 lines
- `bash/agent-deck.bash` — bash, ~630 lines, a small `_agent_deck` entry point
  plus one handler function per command

They are installed by symlink (`install.sh`), so the repo is the single source of
truth: a `git pull` updates the live completions with no reinstall.

This repo does **not** vendor or build agent-deck. It only describes its CLI.

## Why the contents are trustworthy (and how to keep them that way)

The command and option lists were **not** transcribed from `--help` output.
They were extracted from the upstream Go source, because `--help` text in this
CLI is hand-written per command and drifts from the actual `flag.FlagSet`
registrations (several real flags never appear in help, and help truncates).

The extraction lives in `tools/extract-flag-surface.py` — one implementation,
used by both humans and CI, so there is no snippet here to drift from it. It
finds every `flag.NewFlagSet("<name>", …)` and attributes the following
`fs.String/Bool/Int/Duration/Var(...)` calls to that flag-set name. Those names
are conveniently the command paths themselves (`"session start"`,
`"group reorder"`, `"mcp server status"`), which yields an exact
command-path → options map:

```bash
python3 tools/extract-flag-surface.py /path/to/agent-deck
```

Top-level commands come from the `switch` on `args[0]` in
`cmd/agent-deck/main.go`; per-group subcommands and their aliases come from the
`case "…":` lists in `session_cmd.go`, `mcp_cmd.go`, `skill_cmd.go`,
`group_cmd.go`, `remote_cmd.go`, `worktree_cmd.go`, `conductor_cmd.go`,
`fleet_cmd.go`, `plugin_cmd.go`, `costs_cmd.go`, `watcher_cmd.go`,
`openclaw_cmd.go`, `hook_handler.go`. The tool list (`claude`, `codex`, …,
`kiro-cli`) comes from `builtinToolValues` in `internal/ui/settings_panel.go`.

**To update after an upstream release:** the `upstream drift` workflow does the
diffing for you weekly — it regenerates the surface from upstream, fails, and
files an issue containing the delta. To adopt a change: apply the deltas to
**both** completions, refresh the snapshot
(`python3 tools/extract-flag-surface.py <checkout> > spec/flag-surface.txt`), then
run `python3 tools/check-coverage.py` and both suites. That is how `kiro-cli` was
added. Do not rewrite the completions from `--help`.

`spec/flag-surface.txt` is the committed snapshot of that extractor's output and
is the ground truth `tools/check-coverage.py` checks both completions against.
The coverage check is a coarse whole-file search on purpose: mapping each flag to
its exact completion context would re-implement both dispatchers, and the failure
that actually happens is "added to one shell, forgot the other". Both checks were
verified red-green — removing `--insecure-bind` from the bash file makes coverage
fail, and the suites' guard case fails when the `return 0` is dropped.

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
2. **zsh needs a real terminal to complete.** The zsh harnesses use
   `zsh/zpty`. `PS1` passed to `zpty` must contain no spaces and no `>` — zpty
   parses its own argv and a redirect character makes it fail with
   `parse error near '>'`.
3. **bash keeps an escaped word whole.** `foo Comp\ Test <TAB>` gives
   `COMP_WORDS=(foo 'Comp\ Test' '')` — verified against a real interactive bash
   with a probe completion, not assumed. So counting positional words is safe,
   and the bash harnesses reproduce that splitting (they `eval` the line and
   re-escape with `printf %q`) instead of using a naive `read -a`.
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
8. **`__agent_deck_offer_options` and `__agent_deck_offer_subcommands` end with
   an explicit `return 0`.** Without it they inherit `compgen`'s exit status,
   which is 1 when nothing matches the prefix, so the caller falls through to
   positional completion. The window is narrow — a positional candidate has to
   prefix-match a word starting with `-` — but it is reachable: a session titled
   `-dash-session` is legal, and `session start -d<TAB>` then offers that session
   instead of stopping at the (non-matching) option list. `tests/run.bash` pins
   it with a dash-titled fixture session; verified red-green by removing the
   `return 0`. Note that `--zz`-style cases pin nothing here, since no positional
   candidate can match that prefix either way.
9. **`__agent_deck_scan_line` and `__agent_deck_remember_profile` assign to the
   caller's locals** (`pos`, `__agent_deck_gopts`) rather than printing. That is
   the same output-parameter convention bash-completion's own `_init_completion`
   uses; the alternative is a subshell per keystroke. The `_init_completion`
   block itself is deliberately left inline in `_agent_deck` — extracting it
   would hide the fact that it assigns `cur`/`prev`/`words`/`cword` into that
   scope.
10. **Internal plumbing commands are intentionally omitted** from the command
   list: `hook-handler`, `codex-notify`, `notify-daemon`, `run-task`,
   `mcp-proxy`, `creds-refresh`. They exist in `main.go`'s switch but are not
   for humans. Don't "fix" the missing entries.

## Verification procedure

Structural checks (fast, run always):

```bash
zsh -n zsh/_agent-deck
bash -n bash/agent-deck.bash
```

Behavioural checks — these are the ones that catch real breakage. Both suites are
self-validating (non-zero exit on failure) and accept a substring filter:

```bash
tests/run.bash          # 40 assertions, single bash process, ~2s
tests/run.zsh           # 17 assertions, single pty, ~1min
tests/run.bash session  # just the session cases
```

Each suite creates a throwaway profile named `_completion_suite` for the cases
that need a live session and removes it on exit, so a developer's real sessions
are never touched. This is safe because `agent-deck add` only writes a registry
entry — it does not start tmux.

Cost note: do **not** rewrite the suites as one process per case. Sourcing
bash-completion pulls in `/etc/bash_completion.d/*` (one entry on this machine
makes a network call), and each zsh case needs a fresh `compinit`; per-case
processes pushed the bash suite past two minutes, which is why both suites share
one shell. `tests/comptest.{bash,zsh}` remain for eyeballing a single line.

Confirm a real-shell install with
`zsh -ic 'print -r -- ${_comps[agent-deck]}'` (expect `_agent-deck`) and
`bash -ic 'complete -p agent-deck'` (expect `complete -F _agent_deck agent-deck`).

## Design notes

- **zsh** uses `_arguments -C` with `'1:command:…'` + `'*:: :->args'` and
  dispatches on `${words[1]}`, one `__agent_deck_<cmd>` function per command
  group, each repeating the pattern for its own subcommands. Aliases are listed
  as separate `_describe` entries with identical descriptions, which makes zsh
  collapse them into one row (`list  ls  -- list all sessions`).
- **bash** cannot nest that way. `_agent_deck` does four things and stops:
  initialise `cur`/`prev`/`words`, scan the line into `pos[]`, offer the value for
  an option in `$prev`, then hand off to `__agent_deck_complete_arguments_of`,
  which dispatches to one `__agent_deck_<cmd>` handler per command. Handlers read
  the caller's locals (`cur`, `pos`, `npos`) via bash's dynamic scoping.
- Each bash handler follows the same three-step shape, which is the file's main
  readability contract:

  ```bash
  __agent_deck_<cmd>() {
    __agent_deck_offer_subcommands '…' && return   # still on the first argument
    __agent_deck_offer_options "$opts" && return   # user is typing a flag
    …positional completion…
  }
  ```

  `${#pos[@]}` (`npos`) counts positionals strictly *before* the word being
  completed. Handlers derive `argi=$(( npos - 1 ))` (or `- 2` at the third level,
  e.g. `mcp server`) so `argi == 1` reads as "the first argument after the
  subcommand" instead of a bare magic number.
- The shared zsh option-spec arrays (`__agent_deck_common_opts`,
  `__agent_deck_create_opts`) are assigned once when the file loads. They used to
  be built by two setter functions called on every keystroke; that was a hidden
  side effect for no benefit, since the specs are static.
- Option *lists* are duplicated between the two files by necessity (different
  syntaxes). When you add a flag, add it in both, and keep the descriptions in
  the zsh file in sync with the README table.
