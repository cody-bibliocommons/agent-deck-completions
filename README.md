# agent-deck shell completions

[![CI](https://github.com/cody-bibliocommons/agent-deck-completions/actions/workflows/ci.yml/badge.svg)](https://github.com/cody-bibliocommons/agent-deck-completions/actions/workflows/ci.yml)
[![upstream drift](https://github.com/cody-bibliocommons/agent-deck-completions/actions/workflows/upstream-drift.yml/badge.svg)](https://github.com/cody-bibliocommons/agent-deck-completions/actions/workflows/upstream-drift.yml)

Tab completion for **zsh** and **bash** covering
[`agent-deck`](https://github.com/asheshgoplani/agent-deck), a terminal session
manager for AI coding agents.

The option lists come from agent-deck's own `flag.NewFlagSet` definitions in
`cmd/agent-deck/*.go` (v1.10.11), so they match what the binary parses rather
than what its help text claims. [AGENTS.md](AGENTS.md) covers how to regenerate
them after an upstream release.

```
zsh/_agent-deck         zsh completion (compdef, descriptions, per-tag grouping)
bash/agent-deck.bash    bash completion (bash-completion v2 aware, works without it)
install.sh              symlink installer
tests/run.bash          assertion suite for the bash completion
tests/run.zsh           assertion suite for the zsh completion
tests/comptest.bash     print the candidates for one command line (bash)
tests/comptest.zsh      print the candidates for one command line (zsh)
tools/                  CLI-surface extractor and the both-shells coverage check
spec/flag-surface.txt   snapshot of agent-deck's CLI surface, diffed weekly by CI
```

## Install

```bash
git clone <this-repo> ~/git/agent-deck-completions
cd ~/git/agent-deck-completions
./install.sh            # both shells, symlinked (git pull updates them in place)
```

Then open a new shell. For zsh you may need `rm -f ~/.zcompdump*` first if the
completion does not appear.

`./install.sh --bash`, `--zsh`, `--system` (also links zsh into
`/usr/local/share/zsh/site-functions`, which is on zsh's default `$fpath`), and
`--uninstall` are also available.

### Manual install

**zsh.** Put `_agent-deck` in any directory on `$fpath`:

```bash
mkdir -p ~/.local/share/zsh/site-functions
ln -s "$PWD/zsh/_agent-deck" ~/.local/share/zsh/site-functions/_agent-deck
# add to ~/.zshrc BEFORE compinit (oh-my-zsh: before `source $ZSH/oh-my-zsh.sh`)
fpath=(~/.local/share/zsh/site-functions $fpath)
```

`/usr/local/share/zsh/site-functions` and `/usr/share/zsh/site-functions` are
already on zsh's default `$fpath`, so linking there needs no `.zshrc` change.

**bash.** With bash-completion v2 installed, drop the file in the user
completion dir and bash loads it on demand:

```bash
mkdir -p ~/.local/share/bash-completion/completions
ln -s "$PWD/bash/agent-deck.bash" ~/.local/share/bash-completion/completions/agent-deck
```

Without bash-completion, source it from `~/.bashrc`:

```bash
source ~/git/agent-deck-completions/bash/agent-deck.bash
```

## What gets completed

Static: every command, subcommand, alias and option flag.

Dynamic, by shelling out to `agent-deck … --json` (all of these honour a
`-p/--profile` given earlier on the line, so `agent-deck -p work session start <TAB>`
lists the *work* profile's sessions):

| Completes | Source |
|---|---|
| sessions (by title **and** id) | `list --json`. zsh shows status and title as the description |
| groups | `group list --json` (full nested paths) |
| profiles | `profile list --json` |
| MCPs | `mcp list --json` |
| skills / skill sources | `skill list --json`, `skill source list --json` |
| plugins | `plugin list --json` |
| remotes / remote sessions | `remote list --json`, `remote sessions <name> --json` |
| conductors | `conductor list --json` |
| experiments | `try --list --json` |
| git branches (`-w`, `--worktree`, `--into`) | `git for-each-ref refs/heads` |
| tools (`-c`, `--cmd`, `--agent`) | built-in list: claude, codex, gemini, opencode, copilot, crush, cursor, hermes, kiro-cli, pi, shell |
| `session set` fields, `--location`, `--tier`, `--choice`, on/off | built-in enums |
| `--threshold` (`status --stale`) | 24h, 48h, 168h — suggestions, not the valid set; any Go duration works |

Both shells handle session titles that contain spaces. They escape the candidate
on insertion, and a half-typed `Comp\ Te` still matches `Comp Test`.

## Command reference

Global options, valid before the command: `-p/--profile <name>`,
`-g/--group <name>`, `--select <id|title>`, `-h/--help`, `-v/--version`.

Almost every command also accepts `--json` and `-q/--quiet`. The table leaves
those out unless a command has nothing else.

| Command | Arguments | Options |
|---|---|---|
| `add` | `[path]` | `-c/--cmd -t/--title -g/--group -p/--parent --model -w/--worktree -b/--new-branch --location --mcp --plugin --channel --extra-arg -Q/--quick --attach --account --sandbox --sandbox-image --ssh --remote-path --wrapper --yolo --gemini-yolo --title-lock --no-title-sync --no-parent --no-channel-link --no-transition-notify --resume-session --tmux-socket` |
| `launch` | `[path]` | everything in `add` except the ssh/sandbox/quick set, plus `-m/--message --message-file --assert-done --no-assert-done --no-wait --idle-timeout --inherit-group --inherit-telegram-env --wrapper` |
| `try` | `<name>` | `-c/--cmd -l/--list --no-session --sandbox` |
| `list`, `ls` |  | `--json --all` |
| `remove`, `rm` | `<id\|title>` | |
| `rename`, `mv` | `<id\|title> <new-title>` | |
| `status` |  | `-v/--verbose --stale --threshold` |
| `session` | see below | |
| `fleet` | `status`, `recover` | `recover`: `--yes --dry-run --group --limit --spacing --jitter --verify-poll --verify-timeout --max-failures --max-dead-boots --auth-halt-after` |
| `mcp` | `list`, `attached [id]`, `attach <id> <mcp>`, `detach <id> <mcp>`, `server start\|stop\|status` | attach/detach: `--global --restart` |
| `skill` | `list`, `attached [id]`, `attach <id> <skill>`, `detach <id> <skill>`, `source list\|add\|remove` | `--source --restart`; `source add`: `--description` |
| `plugin` | `list`, `attached [id]`, `attach <id> <plugin>`, `detach <id> <plugin>` | `--restart --no-channel-link` |
| `group` | `list`, `show\|info <name>`, `create <name>`, `update <name>`, `delete <name>`, `move <id> <group>`, `change <group> [dest]`, `reorder <name>` | `--resolved --parent --default-path --clear-default-path --max-concurrent --force --to-profile -u/--up -d/--down -p/--position` |
| `worktree`, `wt` | `list`, `info <session>`, `finish <session>`, `cleanup`, `trust-scripts <repo>` | `finish`: `--into --no-merge --keep-branch --force --abort`; `cleanup`: `--force`; `trust-scripts`: `--revoke` |
| `remote` | `add <name> <user@host>`, `remove <name>`, `list`, `sessions [name]`, `attach <name> <session>`, `rename <name> <session> <title>`, `update [name]` | `add`: `--agent-deck-path --profile` |
| `conductor` | `setup <name>`, `teardown <name>`, `status [name]`, `list`, `move <name>`, `migrate-dir <path>` | `setup`: `--agent --description --heartbeat --no-heartbeat --heartbeat-idle-minutes --heartbeat-rules-md --instructions-md --shared-instructions-md --policy-md --shared-policy-md --claude-md --shared-claude-md --no-clear-on-compact --env --env-file`; `teardown`: `--all --remove`; `move`: `--to-profile --force`; `migrate-dir`: `--apply --from --force` |
| `profile` | `list`, `create <name>`, `delete <name>`, `default [name]` | |
| `web` |  | `--listen --token --read-only --no-tui --push --push-test-every --push-vapid-subject --insecure-bind` |
| `costs` | `sync`, `summary`, `recompute` | `-n/--dry-run` |
| `watcher` | `create <kind>`, `import`, `start`, `stop`, `list`, `status`, `test`, `routes`, `install-skill` | `create`: `--name --port --secret --secret-file --topic` |
| `openclaw`, `oc` | `sync`, `bridge`, `status`, `list`, `send` | `--agent --name` |
| `inbox` | `drain [id]` | `--json` |
| `hooks`, `codex-hooks`, `gemini-hooks`, `hermes-hooks`, `cursor-hooks` | `install`, `uninstall`, `status` | |
| `telegram-doctor` |  | `--json --quiet` |
| `update` |  | `--check --version` |
| `migrate-paths` |  | `--dry-run --force` |
| `uninstall` |  | `--dry-run --keep-data --keep-tmux-config -y` |
| `version`, `help`, `debug-dump`, `feedback` |  | |

### `session` subcommands

`start` `stop` `remove` `cleanup`/`prune` `archive` `unarchive` `restart` `revive`
`fork` `handoff` `attach` `focus` `show` `current` `set` `switch-account`
`move`/`mv` `send` `send-keys` `approve` `output` `children` `search`
`set-parent` `unset-parent` `update` `set-transition-notify` `set-title-lock`

| Subcommand | Notable options |
|---|---|
| `start <id>` | `-m/--message --message-file --attach --yolo` |
| `remove <id>` | `--force --all-errored --prune-worktree` |
| `cleanup` | `--days --dry-run -y/--yes --force --include-archived --prune-worktree` |
| `restart [id]` | `--all --env KEY=VALUE --force` |
| `revive` | `--all --name` |
| `fork <id>` | `-t/--title -g/--group -w/--worktree -b/--new-branch --sandbox --sandbox-image --with-state --with-state-and-gitignored` |
| `handoff <id>` | `--max-chars --out` |
| `focus <id>` | `--attach` |
| `set <id> <field> <value>` | fields: `title path command tool wrapper channels plugins extra-args model color claude-session-id gemini-session-id account idle-timeout` |
| `switch-account <id> <account>` | `--no-restart` |
| `move <id> <path>` | `--group --to-profile --copy --force --no-restart` |
| `send <id> <message>` | `--message-file --draft --wait --no-wait --timeout --defer-if-busy --defer-timeout --stream --stream-idle --stream-char-budget --stream-tool-budget` |
| `send-keys <id>` | `--text --named-key --enter --stream` |
| `approve <id> [once\|always\|session]` | `--choice --timeout` |
| `output <id>` | `--copy --pane` |
| `children [id]` | `--follow --until-done --interval --heartbeat` |
| `search <query>` | `--days --limit --tier instant\|balanced\|auto` |
| `set-parent <id> <parent>` | `--inherit-group` |
| `update <id>` | `--parent --no-parent` |
| `set-transition-notify <id> on\|off`, `set-title-lock <id> on\|off` | |

The completions leave out six internal plumbing commands on purpose:
`hook-handler`, `codex-notify`, `notify-daemon`, `run-task`, `mcp-proxy` and
`creds-refresh`. No human types them.

## Testing

```bash
tests/run.bash          # 42 assertions, one bash process, ~2s
tests/run.zsh           # 17 assertions through a single pty, ~1min
zsh -n zsh/_agent-deck && bash -n bash/agent-deck.bash
```

Both suites exit non-zero on failure and take a substring filter
(`tests/run.bash session`). The cases that need a live session create a throwaway
profile and remove it on exit, so your own sessions stay untouched.

To eyeball one command line instead of asserting on it:

```bash
tests/comptest.zsh  'agent-deck session '
tests/comptest.bash 'agent-deck mcp attach '
```

## Maintenance

Two workflows guard this repo:

- **CI** (`ci.yml`) parse-checks and shellchecks every script, checks that both
  completions offer every flag in the snapshot (`tools/check-coverage.py`), runs
  both suites, and round-trips `install.sh`, including whether zsh registers
  `_agent-deck` from a clean `$fpath`.
- **upstream drift** (`upstream-drift.yml`) regenerates `spec/flag-surface.txt`
  from upstream `agent-deck` every Monday. When agent-deck's CLI surface moves, it
  files an issue with the diff and fails. Upstream owns that CLI, so its changes
  are what leave these completions stale.

Refresh the snapshot once you adopt an upstream change:

```bash
python3 tools/extract-flag-surface.py /path/to/agent-deck > spec/flag-surface.txt
python3 tools/check-coverage.py
```

## Known limitations

- `mcp detach`, `skill detach` and `plugin detach` complete from the full catalog
  instead of what a session already has attached. The `… attached --json` payloads
  hold string arrays, which the shared field extractor cannot read.
- `--heartbeat` takes a duration under `session children` and nothing under
  `conductor setup`. Both completions resolve it from the command on the line. If
  that heuristic is ever wrong, bash's positional counting drifts with it.
- Free-text options (`--title`, `--message`, `--model`, durations, …) offer no
  candidates on purpose, so they do not fall back to filename completion.
- bash cannot display per-candidate descriptions; zsh does.

---

Created with the assistance of LLM tools.
