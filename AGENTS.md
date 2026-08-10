# AGENTS.md

Read this before you edit either completion file. It covers where everything
lives, where the command data came from, how to verify a change, and which
constraints will break if you tidy them away.

## What this repo is

Two shell completion scripts for [`agent-deck`](https://github.com/asheshgoplani/agent-deck),
a terminal session manager for AI coding agents. Someone else owns that CLI. This
repo only describes it, and never builds or vendors it.

| Path | Contents |
|---|---|
| `zsh/_agent-deck` | zsh completion, `#compdef` style, built on `_arguments`, ~1100 lines |
| `bash/agent-deck.bash` | bash completion, ~640 lines: a small `_agent_deck` entry point plus one handler per command |
| `install.sh` | symlinks both files into place; `--bash`, `--zsh`, `--system`, `--uninstall` |
| `spec/flag-surface.txt` | snapshot of agent-deck's CLI surface, the ground truth for the checks |
| `tools/extract-flag-surface.py` | regenerates that snapshot from an agent-deck checkout |
| `tools/check-coverage.py` | asserts both completions offer every flag and tool in the snapshot |
| `tests/run.bash`, `tests/run.zsh` | assertion suites, non-zero exit on failure |
| `tests/comptest.bash`, `tests/comptest.zsh` | print the candidates for one command line |
| `.github/workflows/ci.yml` | parse, shellcheck, coverage, suites, install round-trip |
| `.github/workflows/upstream-drift.yml` | weekly check that upstream has not moved |

`install.sh` creates symlinks rather than copies, so `git pull` updates the live
completions and nobody needs to reinstall. On the development machine,
`~/.local/share/{bash-completion/completions,zsh/site-functions}` point straight
into this repo.

## Where the command data came from

The extractor reads agent-deck's Go source. Its `--help` text is hand-written per
command and drifts from the flag sets the binary parses: some real flags never
appear in help, and some help output truncates.

`tools/extract-flag-surface.py` finds every `flag.NewFlagSet("<name>", …)` and
attributes the `fs.String/Bool/Int/Duration/Var(...)` calls that follow it to that
flag set. Those names are the command paths themselves (`"session start"`,
`"group reorder"`, `"mcp server status"`), which is what makes the mapping exact.

```bash
python3 tools/extract-flag-surface.py /path/to/agent-deck
```

It also pulls the top-level commands from the `switch args[0]` dispatch in
`cmd/agent-deck/main.go`, skipping nested switches, and the built-in agent names
from `builtinToolValues` in `internal/ui/settings_panel.go`. Subcommands and their
aliases come from the `case "…":` lists in `session_cmd.go`, `mcp_cmd.go`,
`skill_cmd.go`, `group_cmd.go`, `remote_cmd.go`, `worktree_cmd.go`,
`conductor_cmd.go`, `fleet_cmd.go`, `plugin_cmd.go`, `costs_cmd.go`,
`watcher_cmd.go`, `openclaw_cmd.go` and `hook_handler.go`.

Never rebuild the completions from `--help`.

The completions match agent-deck v1.11.0. `spec/flag-surface.txt` comes from
upstream `main` at `4630080`, whose flag surface matches that tag.

### kiro-cli sits ahead of upstream

`kiro-cli` entered the tool list from a local checkout that was sitting on the
unmerged branch `feat/kiro-cli-tool`. Upstream `main` has no mention of it, and
the v1.11.0 binary does not know it. Keep it: `--cmd` takes any command string,
so offering the name cannot be wrong, and removing it would cost you the entry
once that branch lands.

`EXTRA_TOOLS` in `tools/check-coverage.py` records the divergence, next to
`shell`, which is a legal `--cmd` that was never a `builtinToolValues` entry. That
turns both into declared exceptions instead of mistakes. When the branch merges,
the drift workflow flags the `[tools]` line and you can delete the exception.

## How the live values work

Both scripts shell out to the real binary. Every source is a `--json` subcommand,
read-only, and fast enough that neither script caches anything (each measured at
~0.00s).

They read the JSON with `grep -o '"key"…"value"'` and `sed` rather than `jq`, for
three reasons:

1. `jq` may not be installed, and a completion must never error.
2. It reads both shapes agent-deck emits: pretty-printed `json.MarshalIndent`,
   one field per line, and the compact single-line form that `try --list --json`
   uses.
3. Several subcommands print a plain sentence when a list is empty. `list --json`
   prints `No sessions found in profile 'default'.` A grep yields nothing there. A
   JSON parser would raise.

Every payload exposes its value under `"name"`, with two exceptions. Sessions use
`"id"`, `"title"` and `"status"`, which `awk` parses pairwise, flushing on
`"status"` because that is the first non-`omitempty` field after the other two.
Groups use `"path"`, the full nested group path, which is what the CLI accepts.

### Profile scoping

A `-p/--profile` in front of the subcommand has to reach every data lookup, or the
completions list some other profile's objects. Both scripts scan the words before
the first positional and stop, because `-p` means three different things:

| Context | `-p` means |
|---|---|
| before any subcommand | `--profile` |
| `add`, `launch` | `--parent` |
| `group reorder` | `--position` |

zsh does this in `__agent_deck_scan_gopts`, which runs at the top of `_agent-deck`
before `_arguments`. You cannot read it out of `opt_args` instead: while the user
completes the value of `-g`, `_arguments` has not returned, `opt_args` is empty,
and group completion falls back to the default profile. That was a live bug during
development. Leave the scan alone.

## Gotchas

1. **`status` is read-only in zsh.** It aliases `$?`, so `local status` inside a
   completion function aborts with `read-only variable: status`. The session
   parser calls its variable `sstate`.
2. **zsh needs a real terminal to complete.** The zsh harnesses drive one through
   `zsh/zpty`. Keep spaces and `>` out of the `PS1` you hand to `zpty`: it parses
   its own argv, and a redirect character makes it die with
   `parse error near '>'`.
3. **bash keeps an escaped word whole.** `foo Comp\ Test <TAB>` yields
   `COMP_WORDS=(foo 'Comp\ Test' '')`. A probe completion in a real interactive
   bash confirmed that, so counting positional words is safe. The bash harnesses
   reproduce the same splitting by `eval`ing the line and re-escaping with
   `printf %q`, instead of a naive `read -a`.
4. **Session titles contain spaces.** bash emits candidates `printf %q`-escaped
   and strips backslashes from `$cur` before prefix-matching, so a half-typed
   `Comp\ Te` still matches `Comp Test`. A bare `compgen -W "$list"` would
   word-split multi-word candidates, so don't reach for one.
5. **Escape colons in zsh `_describe` values** (`${val//:/\\:}`). Session titles
   can contain colons, and the description parser eats them otherwise.
6. **`--heartbeat` has two arities.** It takes a duration under
   `session children` and nothing under `conductor setup`.
   `__agent_deck_opt_takes_value` resolves it against `${pos[0]}`. Extend that
   function if you add another ambiguous flag, rather than the flat list above it.
7. **Free-text options return no candidates on purpose.** In bash,
   `__agent_deck_option_value` returns 0 with an empty `COMPREPLY` for
   value-taking options that have no sensible completer, which suppresses bash's
   filename fallback. Return non-zero there and `--title` starts offering files.
8. **`__agent_deck_offer_options` and `__agent_deck_offer_subcommands` end with an
   explicit `return 0`.** Drop it and they inherit `compgen`'s exit status, which
   is 1 when nothing matches the prefix, so the caller falls through to positional
   completion. The window is narrow, since a positional candidate has to
   prefix-match a word starting with `-`, but you can reach it: a session titled
   `-dash-session` is legal, and `session start -d<TAB>` then offers that session
   instead of stopping at the option list. `tests/run.bash` pins this with a
   dash-titled fixture session, verified by deleting the `return 0` and watching
   the case fail. Cases like `--zz` pin nothing, because no positional candidate
   can match that prefix either way.
9. **Two bash helpers write to the caller's locals.** `__agent_deck_scan_line` and
   `__agent_deck_remember_profile` set `pos` and `__agent_deck_gopts` rather than
   printing, the same output-parameter convention bash-completion uses in
   `_init_completion`. Printing would cost a subshell per keystroke. The
   `_init_completion` call stays inline in `_agent_deck` on purpose, since hiding
   it in a wrapper would hide that it assigns `cur`, `prev`, `words` and `cword`
   into that scope.
10. **Six commands are missing on purpose**: `hook-handler`, `codex-notify`,
    `notify-daemon`, `run-task`, `mcp-proxy` and `creds-refresh`. They live in
    `main.go`'s switch, but no human types them. Leave them out.

## How to change something

Adding, renaming or removing a flag touches four places. Work in this order:

1. Regenerate the snapshot from an agent-deck checkout you trust, and check that
   the checkout sits on upstream `main`:
   `python3 tools/extract-flag-surface.py <checkout> > spec/flag-surface.txt`
2. Edit **both** completions. bash keeps flat option strings per command; zsh
   keeps `_arguments` specs with descriptions. Keep the descriptions and the
   README's command table in step with each other.
3. Run `python3 tools/check-coverage.py`. It fails on any snapshot flag or tool
   that only one shell offers.
4. Run both suites, and add a case for behaviour you care about keeping.

Adding a whole command means one more `__agent_deck_<cmd>` handler in each file
plus an entry in the bash dispatch (`__agent_deck_complete_arguments_of`), the zsh
`case` in `_agent-deck`, and `__agent_deck_commands` in both.

## How to verify

Parse-check each file on its own. `bash -n a b` checks `a`, ignores `b`, and
reports success. `zsh -n` behaves the same way, so only a loop tells you the
truth:

```bash
for f in bash/agent-deck.bash install.sh tests/run.bash tests/comptest.bash; do bash -n "$f"; done
for f in zsh/_agent-deck tests/run.zsh tests/comptest.zsh; do zsh -n "$f"; done
shellcheck -s bash bash/agent-deck.bash
shellcheck install.sh tests/run.bash tests/comptest.bash
```

Then run the suites, which is what catches real breakage. Both exit non-zero on
failure and take a substring filter:

```bash
tests/run.bash          # 45 assertions, one bash process, ~2s
tests/run.zsh           # 19 assertions, one pty, ~1min
tests/run.bash session  # only the session cases
```

Each suite creates a throwaway profile called `_completion_suite` for the cases
that need a live session, and removes it on exit, so your own sessions stay
untouched. `agent-deck add` writes a registry entry without starting tmux, which
is what makes that safe.

Cases whose candidates come from the running CLI skip themselves when `agent-deck`
is missing from `PATH`, which is how CI stays honest instead of passing on empty
output. Expect 36 passed and 9 skipped from the bash suite in that state.

Do not rewrite the suites to spawn a process per case. Sourcing bash-completion
pulls in `/etc/bash_completion.d/*`, where one entry on the development machine
makes a network call, and every zsh case needs a fresh `compinit`. Per-case
processes pushed the bash suite past two minutes. Use
`tests/comptest.{bash,zsh}` when you want to eyeball a single line.

Confirm a real-shell install with two commands. `zsh -ic 'print -r -- ${_comps[agent-deck]}'`
should print `_agent-deck`. In bash the loader is lazy, so trigger it first:
`bash -ic '_completion_loader agent-deck; complete -p agent-deck'` should print
`complete -F _agent_deck agent-deck`.

## What CI does

`ci.yml` runs on push and pull request, in four jobs:

- **parse + shellcheck**, one file per invocation, for the reason above.
- **flag coverage in both shells**, running `tools/check-coverage.py`.
- **completion suites**, with `agent-deck` absent, so the live cases skip.
- **install.sh round-trip**, which installs, asserts both symlinks resolve into
  the checkout, uninstalls, asserts they are gone, then reinstalls the zsh half
  and checks that a clean `zsh -fc` with `compinit` registers `_agent-deck`.

`upstream-drift.yml` runs every Monday and on demand. It checks out upstream
agent-deck, regenerates the surface, and diffs it against `spec/flag-surface.txt`.
On a difference it uploads the diff, opens or comments on an issue labelled
`upstream-drift`, and fails. These completions describe a CLI this repo does not
control, so upstream movement is the failure mode worth watching for.

That workflow's `paths` filter does not match when a branch is created, so a fresh
repo needs one manual `gh workflow run upstream-drift.yml` to prove it works.

## Design notes

zsh uses `_arguments -C` with `'1:command:…'` and `'*:: :->args'`, dispatching on
`${words[1]}` to one `__agent_deck_<cmd>` function per command group, each of which
repeats the pattern for its own subcommands. Listing aliases as separate
`_describe` entries with matching descriptions makes zsh collapse them into one
row: `list  ls  -- list all sessions`.

bash cannot nest like that. `_agent_deck` does four things and stops: initialise
`cur`/`prev`/`words`, scan the line into `pos[]`, offer the value for an option in
`$prev`, then hand off to `__agent_deck_complete_arguments_of`, which dispatches to
one handler per command. Handlers read the caller's locals (`cur`, `pos`, `npos`)
through bash's dynamic scoping.

Every bash handler takes the same three-step shape, and that shape is the file's
main readability contract:

```bash
__agent_deck_<cmd>() {
  __agent_deck_offer_subcommands '…' && return   # still on the first argument
  __agent_deck_offer_options "$opts" && return   # user is typing a flag
  …positional completion…
}
```

`npos` (`${#pos[@]}`) counts the positionals before the word being completed.
Handlers derive `argi=$(( npos - 1 ))`, or `- 2` at a third level such as
`mcp server`, so `argi == 1` reads as "the first argument after the subcommand"
rather than as a magic number.

The shared zsh spec arrays `__agent_deck_common_opts` and
`__agent_deck_create_opts` get assigned once, when the file loads. Two setter
functions used to rebuild them on every keystroke, which hid a side effect and
bought nothing, since the specs never change.

The two files duplicate their option lists because their syntaxes differ. That
duplication is why `tools/check-coverage.py` exists.
