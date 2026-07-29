# bash completion for agent-deck — terminal session manager for AI coding agents
#   https://github.com/asheshgoplani/agent-deck
#
# Generated against agent-deck v1.10.11 (commands and flags taken from the CLI's
# own flag sets in cmd/agent-deck/*.go).
#
# Install: see README.md — either
#   ~/.local/share/bash-completion/completions/agent-deck   (dynamic load)
# or source it from ~/.bashrc.
#
# Dynamic completions (sessions, groups, MCPs, skills, profiles, remotes,
# plugins, conductors, experiments) are read from `agent-deck … --json` and
# honour an explicit -p/--profile earlier on the command line.
#
# Reading order is top-down: the entry point first, then one handler per
# command, then the shared helpers, then the data tables.
#
# shellcheck shell=bash
# SC2207: `COMPREPLY=( $(compgen …) )` is the bash-completion idiom — the word
# splitting shellcheck warns about is exactly what builds the candidate array.
# shellcheck disable=SC2207

_agent_deck() {
  # `split` is unused here but must be declared: `_init_completion -s` assigns it,
  # and without the local it would leak into the global scope.
  # shellcheck disable=SC2034
  local cur prev words cword split
  if declare -F _init_completion >/dev/null 2>&1; then
    _init_completion -s || return
  else
    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}
    words=( "${COMP_WORDS[@]}" )
    cword=$COMP_CWORD
  fi

  local -a pos=()
  local npos
  __agent_deck_scan_line
  npos=${#pos[@]}

  [[ $prev == -* ]] && __agent_deck_option_value && return
  (( npos == 0 )) && { __agent_deck_complete_command; return; }
  __agent_deck_complete_arguments_of "${pos[0]}"
}

__agent_deck_complete_command() {
  if [[ $cur == -* ]]; then
    __agent_deck_words '-p --profile -g --group --select -h --help -v --version'
  else
    __agent_deck_words "$__agent_deck_commands"
  fi
}

__agent_deck_complete_arguments_of() {
  case $1 in
    add)                    __agent_deck_add ;;
    launch)                 __agent_deck_launch ;;
    try)                    __agent_deck_try ;;
    list|ls)                __agent_deck_words '--json --all' ;;
    remove|rm|rename|mv)    __agent_deck_session_by_name ;;
    status)                 __agent_deck_words "$__agent_deck_common_opts -v --verbose" ;;
    session)                __agent_deck_session ;;
    fleet)                  __agent_deck_fleet ;;
    mcp)                    __agent_deck_mcp ;;
    skill)                  __agent_deck_skill ;;
    plugin)                 __agent_deck_plugin ;;
    group)                  __agent_deck_group ;;
    worktree|wt)            __agent_deck_worktree ;;
    remote)                 __agent_deck_remote ;;
    conductor)              __agent_deck_conductor ;;
    profile)                __agent_deck_profile ;;
    web)                    __agent_deck_web ;;
    costs)                  __agent_deck_costs ;;
    watcher)                __agent_deck_watcher ;;
    openclaw|oc)            __agent_deck_openclaw ;;
    inbox)                  __agent_deck_inbox ;;
    telegram-doctor)        __agent_deck_words '--json --quiet' ;;
    update)                 __agent_deck_words '--check --version' ;;
    migrate-paths)          __agent_deck_words '--dry-run --force' ;;
    uninstall)              __agent_deck_words '--dry-run --keep-data --keep-tmux-config -y' ;;
    help)                   __agent_deck_offer_subcommands "$__agent_deck_commands" ;;
    hooks|codex-hooks|gemini-hooks|hermes-hooks|cursor-hooks)
                            __agent_deck_offer_subcommands 'install uninstall status' ;;
  esac
}

__agent_deck_add() {
  __agent_deck_offer_options "$__agent_deck_create_opts -Q --quick --attach
    --account --sandbox --sandbox-image --ssh --remote-path --wrapper --yolo
    --gemini-yolo" && return
  __agent_deck_dirs
}

__agent_deck_launch() {
  __agent_deck_offer_options "$__agent_deck_create_opts -m --message
    --message-file --assert-done --no-assert-done --no-wait --idle-timeout
    --inherit-group --inherit-telegram-env --wrapper" && return
  __agent_deck_dirs
}

__agent_deck_try() {
  __agent_deck_offer_options "$__agent_deck_common_opts -c --cmd -l --list
    --no-session --sandbox" && return
  __agent_deck_dyn experiments
}

# `remove`, `rm`, `rename` and `mv` all take one session and nothing else.
__agent_deck_session_by_name() {
  __agent_deck_offer_options "$__agent_deck_common_opts" && return
  (( npos == 1 )) && __agent_deck_dyn sessions
}

__agent_deck_session() {
  __agent_deck_offer_subcommands "$__agent_deck_session_subcmds" && return

  local opts
  case ${pos[1]-} in
    start)       opts="$__agent_deck_common_opts -m --message --message-file --attach --yolo" ;;
    remove)      opts="$__agent_deck_common_opts --force --all-errored --prune-worktree" ;;
    cleanup|prune)
                 opts="$__agent_deck_common_opts --days --dry-run -y --yes --force
                       --include-archived --prune-worktree" ;;
    restart)     opts="$__agent_deck_common_opts --all --env --force" ;;
    revive)      opts="$__agent_deck_common_opts --all --name" ;;
    fork)        opts="$__agent_deck_common_opts -t --title -g --group -w --worktree
                       -b --new-branch --sandbox --sandbox-image --with-state
                       --with-state-and-gitignored" ;;
    handoff)     opts='--json --max-chars --out' ;;
    focus)       opts='--attach' ;;
    move|mv)     opts="$__agent_deck_common_opts --group --to-profile --copy --force --no-restart" ;;
    send)        opts="$__agent_deck_common_opts --message-file --draft --no-wait --wait
                       --timeout --defer-if-busy --defer-timeout --stream --stream-idle
                       --stream-char-budget --stream-tool-budget" ;;
    send-keys)   opts="$__agent_deck_common_opts --text --named-key --enter --stream" ;;
    approve)     opts="$__agent_deck_common_opts --choice --timeout" ;;
    output)      opts="$__agent_deck_common_opts --copy --pane" ;;
    children)    opts="$__agent_deck_common_opts --follow --until-done --interval --heartbeat" ;;
    search)      opts="$__agent_deck_common_opts --days --limit --tier" ;;
    set-parent)  opts="$__agent_deck_common_opts --inherit-group" ;;
    update)      opts="$__agent_deck_common_opts --parent --no-parent" ;;
    switch-account) opts="$__agent_deck_common_opts --no-restart" ;;
    attach)      opts='' ;;
    *)           opts="$__agent_deck_common_opts" ;;
  esac
  __agent_deck_offer_options "$opts" && return

  __agent_deck_session_arguments
}

# Positional arguments of `session <subcommand>`. $argi is 1 for the first
# argument after the subcommand, 2 for the second, and so on.
__agent_deck_session_arguments() {
  local argi=$(( npos - 1 ))
  case ${pos[1]-} in
    cleanup|prune|current) ;;
    set)
      (( argi == 1 )) && __agent_deck_dyn sessions
      (( argi == 2 )) && __agent_deck_words "$__agent_deck_session_fields" ;;
    set-parent)
      (( argi == 1 || argi == 2 )) && __agent_deck_dyn sessions ;;
    set-transition-notify|set-title-lock)
      (( argi == 1 )) && __agent_deck_dyn sessions
      (( argi == 2 )) && __agent_deck_words "$__agent_deck_on_off" ;;
    approve)
      (( argi == 1 )) && __agent_deck_dyn sessions
      (( argi == 2 )) && __agent_deck_words "$__agent_deck_approval_choices" ;;
    move|mv)
      (( argi == 1 )) && __agent_deck_dyn sessions
      (( argi == 2 )) && __agent_deck_dirs ;;
    *)
      (( argi == 1 )) && __agent_deck_dyn sessions ;;
  esac
}

__agent_deck_fleet() {
  __agent_deck_offer_subcommands 'status recover help' && return
  case ${pos[1]-} in
    recover) __agent_deck_words "$__agent_deck_common_opts --yes --dry-run --group
               --limit --spacing --jitter --verify-poll --verify-timeout
               --max-failures --max-dead-boots --auth-halt-after" ;;
    *)       __agent_deck_words "$__agent_deck_common_opts" ;;
  esac
}

__agent_deck_mcp() {
  __agent_deck_offer_subcommands 'list ls attached attach detach server help' && return
  [[ ${pos[1]-} == server ]] && { __agent_deck_mcp_server; return; }

  local opts=$__agent_deck_common_opts
  case ${pos[1]-} in
    attach|detach) opts+=' --global --restart' ;;
  esac
  __agent_deck_offer_options "$opts" && return

  local argi=$(( npos - 1 ))
  case ${pos[1]-} in
    list|ls) ;;
    attach|detach)
      (( argi == 1 )) && __agent_deck_dyn sessions
      (( argi == 2 )) && __agent_deck_dyn mcps ;;
    *)
      (( argi == 1 )) && __agent_deck_dyn sessions ;;
  esac
}

__agent_deck_mcp_server() {
  local argi=$(( npos - 2 ))
  (( argi == 0 )) && { __agent_deck_words 'start stop status help'; return; }
  __agent_deck_offer_options "$__agent_deck_common_opts" && return
  (( argi == 1 )) && __agent_deck_dyn mcps
}

__agent_deck_skill() {
  __agent_deck_offer_subcommands 'list ls attached attach detach source help' && return
  [[ ${pos[1]-} == source ]] && { __agent_deck_skill_source; return; }

  local opts=$__agent_deck_common_opts
  case ${pos[1]-} in
    attach|detach) opts+=' --source --restart' ;;
    list|ls)       opts+=' --source' ;;
  esac
  __agent_deck_offer_options "$opts" && return

  local argi=$(( npos - 1 ))
  case ${pos[1]-} in
    list|ls) ;;
    attach|detach)
      (( argi == 1 )) && __agent_deck_dyn sessions
      (( argi == 2 )) && __agent_deck_dyn skills ;;
    *)
      (( argi == 1 )) && __agent_deck_dyn sessions ;;
  esac
}

__agent_deck_skill_source() {
  local argi=$(( npos - 2 ))
  (( argi == 0 )) && { __agent_deck_words 'list add remove rm help'; return; }
  __agent_deck_offer_options "$__agent_deck_common_opts --description" && return
  case ${pos[2]-} in
    remove|rm) (( argi == 1 )) && __agent_deck_dyn skill-sources ;;
    add)       (( argi == 2 )) && __agent_deck_dirs ;;
  esac
}

__agent_deck_plugin() {
  __agent_deck_offer_subcommands 'list ls attached attach detach help' && return

  local opts=$__agent_deck_common_opts
  case ${pos[1]-} in
    attach|detach) opts+=' --restart --no-channel-link' ;;
  esac
  __agent_deck_offer_options "$opts" && return

  local argi=$(( npos - 1 ))
  case ${pos[1]-} in
    list|ls) ;;
    attach|detach)
      (( argi == 1 )) && __agent_deck_dyn sessions
      (( argi == 2 )) && __agent_deck_dyn plugins ;;
    *)
      (( argi == 1 )) && __agent_deck_dyn sessions ;;
  esac
}

__agent_deck_group() {
  __agent_deck_offer_subcommands 'list ls show info create new update set delete rm
    remove move mv change reparent reorder sort help' && return

  local opts=$__agent_deck_common_opts
  case ${pos[1]-} in
    show|info)        opts+=' --resolved' ;;
    create|new)       opts+=' --parent --default-path --max-concurrent' ;;
    update|set)       opts+=' --default-path --clear-default-path --max-concurrent' ;;
    delete|rm|remove) opts+=' --force' ;;
    move|mv)          opts+=' --force --to-profile' ;;
    reorder|sort)     opts+=' -u --up -d --down -p --position' ;;
  esac
  __agent_deck_offer_options "$opts" && return

  local argi=$(( npos - 1 ))
  case ${pos[1]-} in
    list|ls|create|new) ;;
    move|mv)
      (( argi == 1 )) && __agent_deck_dyn sessions
      (( argi == 2 )) && __agent_deck_dyn groups ;;
    change|reparent)
      (( argi == 1 || argi == 2 )) && __agent_deck_dyn groups ;;
    *)
      (( argi == 1 )) && __agent_deck_dyn groups ;;
  esac
}

__agent_deck_worktree() {
  __agent_deck_offer_subcommands 'list ls info finish cleanup help' && return

  local opts='--json'
  case ${pos[1]-} in
    finish)  opts+=' --into --no-merge --keep-branch --force --abort' ;;
    cleanup) opts+=' --force' ;;
  esac
  __agent_deck_offer_options "$opts" && return

  local argi=$(( npos - 1 ))
  case ${pos[1]-} in
    info|finish) (( argi == 1 )) && __agent_deck_dyn sessions ;;
  esac
}

__agent_deck_remote() {
  __agent_deck_offer_subcommands 'add remove rm list ls sessions attach rename update' && return

  case ${pos[1]-} in
    add) __agent_deck_offer_options '--agent-deck-path --profile' && return ;;
    *)   __agent_deck_offer_options '--json' && return ;;
  esac

  local argi=$(( npos - 1 ))
  case ${pos[1]-} in
    add) ;;
    attach|rename)
      (( argi == 1 )) && __agent_deck_dyn remotes
      (( argi == 2 )) && __agent_deck_dyn remote-sessions "${pos[2]-}" ;;
    *)
      (( argi == 1 )) && __agent_deck_dyn remotes ;;
  esac
}

__agent_deck_conductor() {
  __agent_deck_offer_subcommands 'setup teardown status list move migrate-dir help' && return

  local opts='--json'
  case ${pos[1]-} in
    setup)       opts+=' --agent --description --heartbeat --no-heartbeat
                        --heartbeat-idle-minutes --heartbeat-rules-md --instructions-md
                        --shared-instructions-md --policy-md --shared-policy-md
                        --claude-md --shared-claude-md --no-clear-on-compact
                        --env --env-file' ;;
    teardown)    opts+=' --all --remove' ;;
    list)        opts+=' --profile' ;;
    move)        opts="$__agent_deck_common_opts --to-profile --force" ;;
    migrate-dir) opts+=' --apply --from --force' ;;
  esac
  __agent_deck_offer_options "$opts" && return

  local argi=$(( npos - 1 ))
  case ${pos[1]-} in
    list) ;;
    migrate-dir) (( argi == 1 )) && __agent_deck_dirs ;;
    *)           (( argi == 1 )) && __agent_deck_dyn conductors ;;
  esac
}

__agent_deck_profile() {
  __agent_deck_offer_subcommands 'list create delete default help' && return
  __agent_deck_offer_options "$__agent_deck_common_opts" && return
  case ${pos[1]-} in
    delete|default) (( npos == 2 )) && __agent_deck_dyn profiles ;;
  esac
}

__agent_deck_web() {
  __agent_deck_words '--listen --token --read-only --no-tui --push
    --push-test-every --push-vapid-subject --insecure-bind'
}

__agent_deck_costs() {
  __agent_deck_offer_subcommands 'sync summary recompute' && return
  case ${pos[1]-} in
    summary) __agent_deck_words '--json' ;;
    *)       __agent_deck_words '-n --dry-run' ;;
  esac
}

__agent_deck_watcher() {
  __agent_deck_offer_subcommands 'create import start stop list status test routes
    install-skill help' && return
  case ${pos[1]-} in
    create)
      __agent_deck_offer_options '--name --port --secret --secret-file --topic' && return
      (( npos == 2 )) && __agent_deck_words "$__agent_deck_watcher_kinds" ;;
    list|status|routes)
      __agent_deck_words '--json' ;;
  esac
}

__agent_deck_openclaw() {
  __agent_deck_offer_subcommands 'sync bridge status list send help' && return
  case ${pos[1]-} in
    bridge) __agent_deck_words '--agent --name' ;;
    send)   __agent_deck_words '--agent' ;;
    *)      __agent_deck_words '--json' ;;
  esac
}

__agent_deck_inbox() {
  __agent_deck_offer_subcommands 'drain' && return
  __agent_deck_offer_options '--json' && return
  (( npos == 2 )) && __agent_deck_dyn sessions
}

# Value completion for the option sitting in $prev. Returns 0 when it handled the
# word — including deliberately handling it with no candidates, so free-text
# options such as --title do not fall back to filename completion.
__agent_deck_option_value() {
  case $prev in
    -p|--profile)         __agent_deck_profile_or_parent; return 0 ;;
    --parent|--select)    __agent_deck_dyn sessions; return 0 ;;
    -g|--group)           __agent_deck_dyn groups; return 0 ;;
    --to-profile)         __agent_deck_dyn profiles; return 0 ;;
    -c|--cmd|--agent)     __agent_deck_words "$__agent_deck_tools"; return 0 ;;
    -w|--worktree|--into) __agent_deck_dyn branches; return 0 ;;
    --mcp)                __agent_deck_dyn mcps; return 0 ;;
    --plugin)             __agent_deck_dyn plugins; return 0 ;;
    --source)             __agent_deck_dyn skill-sources; return 0 ;;
    --location)           __agent_deck_words "$__agent_deck_worktree_locations"; return 0 ;;
    --tier)               __agent_deck_words "$__agent_deck_search_tiers"; return 0 ;;
    --choice)             __agent_deck_words "$__agent_deck_approval_choices"; return 0 ;;
    --remote-path|--default-path|--from)
                          __agent_deck_dirs; return 0 ;;
    --ssh)                __agent_deck_ssh_hosts; return 0 ;;
    --message-file|--env-file|--out|--secret-file|--heartbeat-rules-md|\
    --instructions-md|--shared-instructions-md|--policy-md|--shared-policy-md|\
    --claude-md|--shared-claude-md)
                          __agent_deck_files; return 0 ;;
  esac
  __agent_deck_opt_takes_value "$prev" && { COMPREPLY=(); return 0; }
  return 1
}

# `-p` is the global --profile until a subcommand appears, and --parent after
# `add`/`launch`. (After `group reorder` it is --position, which takes a number
# and so completes to nothing.)
__agent_deck_profile_or_parent() {
  if (( ${#pos[@]} == 0 )); then
    __agent_deck_dyn profiles
  elif [[ ${pos[0]} == add || ${pos[0]} == launch ]]; then
    __agent_deck_dyn sessions
  else
    COMPREPLY=()
  fi
}

# Split the line into the positional words typed *before* $cur, and capture an
# explicit global -p/--profile so the data helpers query the right profile.
# Outputs (assigned in the caller's scope, as bash-completion's own helpers do):
#   pos[]                 positional words, pos[0] being the command
#   __agent_deck_gopts[]  either empty or (--profile <name>)
__agent_deck_scan_line() {
  local i=1 word
  pos=()
  __agent_deck_gopts=()
  while (( i < cword )); do
    word=${words[i]}
    if [[ $word != -* || $word == - ]]; then
      pos+=( "$word" )
      (( i++ ))
      continue
    fi
    __agent_deck_remember_profile "$word" "${words[i+1]-}"
    if [[ $word != *=* ]] && __agent_deck_opt_takes_value "$word"; then
      (( i += 2 ))
    else
      (( i++ ))
    fi
  done
}

# Only a -p/--profile that precedes the subcommand is the global profile flag.
__agent_deck_remember_profile() {
  local flag=$1 next=$2
  (( ${#pos[@]} == 0 )) || return 0
  case $flag in
    -p=*|--profile=*) __agent_deck_gopts=(--profile "${flag#*=}") ;;
    -p|--profile)     [[ -n $next ]] && __agent_deck_gopts=(--profile "$next") ;;
  esac
}

# Offer $1 as the option list when the user is typing a flag. Returns 0 when it
# took the word, so callers read: `__agent_deck_offer_options "…" && return`.
# The explicit `return 0` matters: compgen exits 1 when nothing matches the
# prefix, and inheriting that would fall through to positional completion and
# offer sessions or filenames for a typo like `--zz`.
__agent_deck_offer_options() {
  [[ $cur == -* ]] || return 1
  __agent_deck_words "$1"
  return 0
}

# Offer $1 as subcommand names while the user is still on the command's first
# argument.
__agent_deck_offer_subcommands() {
  (( npos == 1 )) && [[ $cur != -* ]] || return 1
  __agent_deck_words "$1"
  return 0
}

# Complete from a space-separated word list (options, subcommands, enums).
__agent_deck_words() {
  local IFS=$' \t\n'
  COMPREPLY=( $(compgen -W "$1" -- "$cur") )
}

# Complete from a newline-separated list, tolerating values that contain spaces
# (session titles routinely do). Candidates are emitted %q-escaped so the shell
# inserts them correctly; $cur is un-escaped first so a half-typed "Comp\ Te"
# still matches "Comp Test".
__agent_deck_dyn() {
  local kind=$1 argument=${2-} candidate raw=${cur//\\/}
  COMPREPLY=()
  while IFS= read -r candidate; do
    [[ -n $candidate ]] || continue
    [[ $candidate == "$raw"* ]] || continue
    COMPREPLY+=( "$(printf '%q' "$candidate")" )
  done < <(__agent_deck_data "$kind" "$argument")
}

# bash-completion's _filedir handles quoting and the trailing slash on
# directories; bare compgen does not, so it is only the fallback.
__agent_deck_files() {
  if declare -F _filedir >/dev/null 2>&1; then
    _filedir
  else
    COMPREPLY=( $(compgen -f -- "$cur") )
  fi
}

__agent_deck_dirs() {
  if declare -F _filedir >/dev/null 2>&1; then
    _filedir -d
  else
    COMPREPLY=( $(compgen -d -- "$cur") )
  fi
}

__agent_deck_ssh_hosts() {
  COMPREPLY=()
  declare -F _known_hosts_real >/dev/null 2>&1 && _known_hosts_real -- "$cur"
}

# Live values, one per line. Every payload but sessions and groups exposes the
# value under "name"; sessions use id/title/status and groups use the full
# nested "path", which is what the CLI accepts.
__agent_deck_data() {
  case $1 in
    sessions)
      # Titles first (what people actually type), then ids.
      agent-deck "${__agent_deck_gopts[@]}" list --json 2>/dev/null | awk -F'"' '
        /"id"[[:space:]]*:/    { id = $4 }
        /"title"[[:space:]]*:/ { if (id != "") { print $4; print id; id = "" } }'
      ;;
    groups)        __agent_deck_json_field path group list --json ;;
    profiles)      __agent_deck_json_field name profile list --json ;;
    mcps)          __agent_deck_json_field name mcp list --json ;;
    skills)        __agent_deck_json_field name skill list --json ;;
    skill-sources) __agent_deck_json_field name skill source list --json ;;
    plugins)       __agent_deck_json_field name plugin list --json ;;
    remotes)       __agent_deck_json_field name remote list --json ;;
    conductors)    __agent_deck_json_field name conductor list --json ;;
    experiments)   __agent_deck_json_field name try --list --json ;;
    branches)      git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null ;;
    remote-sessions)
      [[ -n ${2-} && ${2-} != -* ]] || return 0
      __agent_deck_json_field title remote sessions "$2" --json
      ;;
  esac
}

# Pull every value of a JSON string field out of an agent-deck --json payload.
# Handles both the pretty-printed (MarshalIndent) and compact shapes, and
# quietly yields nothing when the command prints a plain "none found" message.
__agent_deck_json_field() {
  local key=$1; shift
  command -v agent-deck >/dev/null 2>&1 || return 1
  agent-deck "${__agent_deck_gopts[@]}" "$@" 2>/dev/null |
    grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" 2>/dev/null |
    sed -e 's/^[^:]*:[[:space:]]*"//' -e 's/"$//'
}

# Options that consume the following word. `--heartbeat` is a duration under
# `session children` but a boolean under `conductor setup`, so it is resolved
# against the command already on the line.
__agent_deck_opt_takes_value() {
  case $1 in
    --heartbeat) [[ ${pos[0]-} == session ]] ;;
    -p|-g|-c|-t|-m|-w) return 0 ;;
    --profile|--group|--select|--parent|--cmd|--title|--model|--worktree|--location) return 0 ;;
    --mcp|--plugin|--channel|--extra-arg|--resume-session|--tmux-socket|--account) return 0 ;;
    --sandbox-image|--ssh|--remote-path|--wrapper|--message|--message-file) return 0 ;;
    --idle-timeout|--days|--limit|--tier|--timeout|--defer-timeout|--stream-idle) return 0 ;;
    --stream-char-budget|--stream-tool-budget|--max-chars|--out|--choice) return 0 ;;
    --named-key|--text|--source|--to-profile|--into|--default-path) return 0 ;;
    --max-concurrent|--position|--env|--env-file|--name|--version|--from) return 0 ;;
    --spacing|--jitter|--verify-poll|--verify-timeout|--max-failures) return 0 ;;
    --max-dead-boots|--auth-halt-after|--listen|--token|--push-test-every) return 0 ;;
    --push-vapid-subject|--agent|--description|--heartbeat-idle-minutes) return 0 ;;
    --heartbeat-rules-md|--instructions-md|--shared-instructions-md) return 0 ;;
    --policy-md|--shared-policy-md|--claude-md|--shared-claude-md) return 0 ;;
    --agent-deck-path|--port|--secret|--secret-file|--topic|--interval) return 0 ;;
    *) return 1 ;;
  esac
}

__agent_deck_commands='add launch try list ls remove rm rename mv status session
  fleet mcp skill plugin group worktree wt web remote conductor openclaw oc costs
  inbox watcher telegram-doctor profile update feedback debug-dump migrate-paths
  uninstall version help codex-hooks gemini-hooks hermes-hooks cursor-hooks hooks'

__agent_deck_session_subcmds='start stop remove cleanup prune archive unarchive
  restart revive fork handoff attach focus show current set switch-account move mv
  send send-keys approve output children search set-parent unset-parent update
  set-transition-notify set-title-lock help'

__agent_deck_session_fields='title path command tool wrapper channels plugins
  extra-args model color claude-session-id gemini-session-id account idle-timeout'

# Upstream's builtinToolValues, plus two deliberate extras: `shell` (a valid
# --cmd, not a builtin tool) and `kiro-cli` (upstream's feat/kiro-cli-tool
# branch, not yet on main). --cmd takes an arbitrary command, so neither can be
# wrong; tools/check-coverage.py holds this list to the snapshot.
__agent_deck_tools='claude codex gemini opencode copilot crush cursor hermes kiro-cli pi shell'

__agent_deck_approval_choices='once always session'
__agent_deck_worktree_locations='sibling subdirectory'
__agent_deck_search_tiers='instant balanced auto'
__agent_deck_watcher_kinds='webhook ntfy github slack'
__agent_deck_on_off='on off'

__agent_deck_common_opts='--json --quiet -q'

# Assigned after __agent_deck_common_opts, which it interpolates.
__agent_deck_create_opts="$__agent_deck_common_opts -c --cmd -t --title -g --group
  -p --parent --model -w --worktree -b --new-branch --location --mcp --plugin
  --channel --extra-arg --no-channel-link --no-parent --no-title-sync --title-lock
  --no-transition-notify --resume-session --tmux-socket"

complete -F _agent_deck agent-deck
