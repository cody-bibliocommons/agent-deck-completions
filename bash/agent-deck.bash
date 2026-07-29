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

# --- data helpers ----------------------------------------------------------

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

# Complete from a newline-separated list, tolerating values that contain spaces
# (session titles routinely do). Candidates are emitted %q-escaped so the shell
# inserts them correctly; $cur is un-escaped first so a half-typed
# "Comp\ Te" still matches "Comp Test".
__agent_deck_dyn() {
  local kind=$1 arg=${2-} cand raw
  raw=${cur//\\/}
  COMPREPLY=()
  while IFS= read -r cand; do
    [[ -n $cand ]] || continue
    [[ $cand == "$raw"* ]] || continue
    COMPREPLY+=( "$(printf '%q' "$cand")" )
  done < <(__agent_deck_data "$kind" "$arg")
}

# Complete from a space-separated word list (options, subcommands, enums).
__agent_deck_words() {
  local IFS=$' \t\n'
  COMPREPLY=( $(compgen -W "$1" -- "$cur") )
}

__agent_deck_dirs() { COMPREPLY=(); compopt -o nospace 2>/dev/null; COMPREPLY=( $(compgen -d -- "$cur") ); }
__agent_deck_files() { COMPREPLY=(); COMPREPLY=( $(compgen -f -- "$cur") ); }

# --- static tables ---------------------------------------------------------

__agent_deck_commands='add launch try list ls remove rm rename mv status session
  fleet mcp skill plugin group worktree wt web remote conductor openclaw oc costs
  inbox watcher telegram-doctor profile update feedback debug-dump migrate-paths
  uninstall version help codex-hooks gemini-hooks hermes-hooks cursor-hooks hooks'

__agent_deck_tools='claude codex gemini opencode copilot crush cursor hermes kiro-cli pi shell'

__agent_deck_session_subcmds='start stop remove cleanup prune archive unarchive
  restart revive fork handoff attach focus show current set switch-account move mv
  send send-keys approve output children search set-parent unset-parent update
  set-transition-notify set-title-lock help'

__agent_deck_session_fields='title path command tool wrapper channels plugins
  extra-args model color claude-session-id gemini-session-id account idle-timeout'

__agent_deck_common_opts='--json --quiet -q'

# add/launch shared options
__agent_deck_create_opts="$__agent_deck_common_opts -c --cmd -t --title -g --group
  -p --parent --model -w --worktree -b --new-branch --location --mcp --plugin
  --channel --extra-arg --no-channel-link --no-parent --no-title-sync --title-lock
  --no-transition-notify --resume-session --tmux-socket"

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

# Value completion for the option sitting in $prev. Returns 0 when it handled
# the word — including deliberately handling it with no candidates, so free-text
# options such as --title do not fall back to filenames.
__agent_deck_option_value() {
  case $prev in
    -p|--profile)
      if (( ${#pos[@]} == 0 )); then __agent_deck_dyn profiles
      elif [[ ${pos[0]} == add || ${pos[0]} == launch ]]; then __agent_deck_dyn sessions
      fi
      return 0 ;;
    --parent)          __agent_deck_dyn sessions; return 0 ;;
    -g|--group|--to-profile)
      if [[ $prev == --to-profile ]]; then __agent_deck_dyn profiles; else __agent_deck_dyn groups; fi
      return 0 ;;
    --select)          __agent_deck_dyn sessions; return 0 ;;
    -c|--cmd|--agent)  __agent_deck_words "$__agent_deck_tools"; return 0 ;;
    -w|--worktree|--into) __agent_deck_dyn branches; return 0 ;;
    --mcp)             __agent_deck_dyn mcps; return 0 ;;
    --plugin)          __agent_deck_dyn plugins; return 0 ;;
    --source)          __agent_deck_dyn skill-sources; return 0 ;;
    --location)        __agent_deck_words 'sibling subdirectory'; return 0 ;;
    --tier)            __agent_deck_words 'instant balanced auto'; return 0 ;;
    --choice)          __agent_deck_words 'once always session'; return 0 ;;
    --message-file|--env-file|--out|--secret-file|--heartbeat-rules-md|\
    --instructions-md|--shared-instructions-md|--policy-md|--shared-policy-md|\
    --claude-md|--shared-claude-md)
      __agent_deck_files; return 0 ;;
    --remote-path|--default-path|--from)
      __agent_deck_dirs; return 0 ;;
    --ssh)
      COMPREPLY=(); command -v _known_hosts_real >/dev/null 2>&1 && _known_hosts_real -- "$cur"
      return 0 ;;
  esac
  # Any other value-taking option: accept free text, suggest nothing.
  __agent_deck_opt_takes_value "$prev" && { COMPREPLY=(); return 0; }
  return 1
}

# --- main ------------------------------------------------------------------

_agent_deck() {
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

  # Split the line into the positional words typed *before* $cur, capturing an
  # explicit global -p/--profile on the way so the data helpers query the right
  # profile. `-p` only counts as --profile while no subcommand has been seen:
  # after `add` it means --parent, and after `group reorder` it means --position.
  local -a pos=()
  local i=1 w
  __agent_deck_gopts=()
  while (( i < cword )); do
    w=${words[i]}
    if [[ $w == -* && $w != - ]]; then
      case $w in
        -p=*|--profile=*)
          (( ${#pos[@]} == 0 )) && __agent_deck_gopts=(--profile "${w#*=}") ;;
        -p|--profile)
          (( ${#pos[@]} == 0 )) && (( i + 1 < cword )) &&
            __agent_deck_gopts=(--profile "${words[i+1]}") ;;
      esac
      if [[ $w != *=* ]] && __agent_deck_opt_takes_value "$w"; then
        (( i += 2 ))
      else
        (( i++ ))
      fi
    else
      pos+=( "$w" )
      (( i++ ))
    fi
  done

  local cmd=${pos[0]-} sub=${pos[1]-} sub2=${pos[2]-}
  local npos=${#pos[@]}

  # 1. value for the option in $prev
  if [[ $prev == -* ]]; then
    __agent_deck_option_value && return
  fi

  # 2. no command yet: global options or the command name
  if (( npos == 0 )); then
    if [[ $cur == -* ]]; then
      __agent_deck_words '-p --profile -g --group --select -h --help -v --version'
    else
      __agent_deck_words "$__agent_deck_commands"
    fi
    return
  fi

  # 3. per-command options and positionals
  local opts=''
  case $cmd in
    add)
      opts="$__agent_deck_create_opts -Q --quick --attach --account --sandbox
            --sandbox-image --ssh --remote-path --wrapper --yolo --gemini-yolo"
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      __agent_deck_dirs; return ;;
    launch)
      opts="$__agent_deck_create_opts -m --message --message-file --assert-done
            --no-assert-done --no-wait --idle-timeout --inherit-group
            --inherit-telegram-env --wrapper"
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      __agent_deck_dirs; return ;;
    try)
      opts="$__agent_deck_common_opts -c --cmd -l --list --no-session --sandbox"
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      __agent_deck_dyn experiments; return ;;
    list|ls)
      __agent_deck_words '--json --all'; return ;;
    remove|rm)
      [[ $cur == -* ]] && { __agent_deck_words "$__agent_deck_common_opts"; return; }
      (( npos == 1 )) && __agent_deck_dyn sessions
      return ;;
    rename|mv)
      [[ $cur == -* ]] && { __agent_deck_words "$__agent_deck_common_opts"; return; }
      (( npos == 1 )) && __agent_deck_dyn sessions
      return ;;
    status)
      __agent_deck_words "$__agent_deck_common_opts -v --verbose"; return ;;
    session)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words "$__agent_deck_session_subcmds"; return
      fi
      case $sub in
        start)
          opts="$__agent_deck_common_opts -m --message --message-file --attach --yolo" ;;
        remove)
          opts="$__agent_deck_common_opts --force --all-errored --prune-worktree" ;;
        cleanup|prune)
          opts="$__agent_deck_common_opts --days --dry-run -y --yes --force
                --include-archived --prune-worktree" ;;
        restart)
          opts="$__agent_deck_common_opts --all --env --force" ;;
        revive)
          opts="$__agent_deck_common_opts --all --name" ;;
        fork)
          opts="$__agent_deck_common_opts -t --title -g --group -w --worktree
                -b --new-branch --sandbox --sandbox-image --with-state
                --with-state-and-gitignored" ;;
        handoff)   opts='--json --max-chars --out' ;;
        focus)     opts='--attach' ;;
        move|mv)
          opts="$__agent_deck_common_opts --group --to-profile --copy --force --no-restart" ;;
        send)
          opts="--json -q --quiet --message-file --draft --no-wait --wait --timeout
                --defer-if-busy --defer-timeout --stream --stream-idle
                --stream-char-budget --stream-tool-budget" ;;
        send-keys) opts='--json -q --quiet --text --named-key --enter --stream' ;;
        approve)   opts='--json -q --quiet --choice --timeout' ;;
        output)    opts="$__agent_deck_common_opts --copy --pane" ;;
        children)
          opts="$__agent_deck_common_opts --follow --until-done --interval --heartbeat" ;;
        search)    opts="$__agent_deck_common_opts --days --limit --tier" ;;
        set-parent) opts="$__agent_deck_common_opts --inherit-group" ;;
        update)    opts="$__agent_deck_common_opts --parent --no-parent" ;;
        switch-account) opts="$__agent_deck_common_opts --no-restart" ;;
        attach)    opts='' ;;
        *)         opts="$__agent_deck_common_opts" ;;
      esac
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      case $sub in
        cleanup|prune|current) return ;;
        set)
          (( npos == 2 )) && { __agent_deck_dyn sessions; return; }
          (( npos == 3 )) && { __agent_deck_words "$__agent_deck_session_fields"; return; }
          return ;;
        set-parent)
          (( npos == 2 || npos == 3 )) && __agent_deck_dyn sessions
          return ;;
        set-transition-notify|set-title-lock)
          (( npos == 2 )) && { __agent_deck_dyn sessions; return; }
          (( npos == 3 )) && { __agent_deck_words 'on off'; return; }
          return ;;
        approve)
          (( npos == 2 )) && { __agent_deck_dyn sessions; return; }
          (( npos == 3 )) && { __agent_deck_words 'once always session'; return; }
          return ;;
        move)
          (( npos == 2 )) && { __agent_deck_dyn sessions; return; }
          (( npos == 3 )) && { __agent_deck_dirs; return; }
          return ;;
        switch-account)
          (( npos == 2 )) && __agent_deck_dyn sessions
          return ;;
        *)
          (( npos == 2 )) && __agent_deck_dyn sessions
          return ;;
      esac ;;
    fleet)
      if (( npos == 1 )) && [[ $cur != -* ]]; then __agent_deck_words 'status recover help'; return; fi
      case $sub in
        recover)
          opts="$__agent_deck_common_opts --yes --dry-run --group --limit --spacing
                --jitter --verify-poll --verify-timeout --max-failures
                --max-dead-boots --auth-halt-after" ;;
        *) opts="$__agent_deck_common_opts" ;;
      esac
      __agent_deck_words "$opts"; return ;;
    mcp)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'list ls attached attach detach server help'; return
      fi
      if [[ $sub == server ]]; then
        (( npos == 2 )) && [[ $cur != -* ]] && { __agent_deck_words 'start stop status help'; return; }
        [[ $cur == -* ]] && { __agent_deck_words "$__agent_deck_common_opts"; return; }
        (( npos == 3 )) && __agent_deck_dyn mcps
        return
      fi
      case $sub in
        attach|detach) opts="$__agent_deck_common_opts --global --restart" ;;
        *)             opts="$__agent_deck_common_opts" ;;
      esac
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      (( npos == 2 )) && [[ $sub != list && $sub != ls ]] && { __agent_deck_dyn sessions; return; }
      (( npos == 3 )) && [[ $sub == attach || $sub == detach ]] && { __agent_deck_dyn mcps; return; }
      return ;;
    skill)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'list ls attached attach detach source help'; return
      fi
      if [[ $sub == source ]]; then
        (( npos == 2 )) && [[ $cur != -* ]] && { __agent_deck_words 'list add remove rm help'; return; }
        [[ $cur == -* ]] && { __agent_deck_words "$__agent_deck_common_opts --description"; return; }
        if [[ $sub2 == remove || $sub2 == rm ]]; then
          (( npos == 3 )) && { __agent_deck_dyn skill-sources; return; }
        elif [[ $sub2 == add ]]; then
          (( npos == 4 )) && { __agent_deck_dirs; return; }
        fi
        return
      fi
      case $sub in
        attach|detach) opts="$__agent_deck_common_opts --source --restart" ;;
        list|ls)       opts="$__agent_deck_common_opts --source" ;;
        *)             opts="$__agent_deck_common_opts" ;;
      esac
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      (( npos == 2 )) && [[ $sub != list && $sub != ls ]] && { __agent_deck_dyn sessions; return; }
      (( npos == 3 )) && [[ $sub == attach || $sub == detach ]] && { __agent_deck_dyn skills; return; }
      return ;;
    plugin)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'list ls attached attach detach help'; return
      fi
      case $sub in
        attach|detach) opts="$__agent_deck_common_opts --restart --no-channel-link" ;;
        *)             opts="$__agent_deck_common_opts" ;;
      esac
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      (( npos == 2 )) && [[ $sub != list && $sub != ls ]] && { __agent_deck_dyn sessions; return; }
      (( npos == 3 )) && [[ $sub == attach || $sub == detach ]] && { __agent_deck_dyn plugins; return; }
      return ;;
    group)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'list ls show info create new update set delete rm remove
          move mv change reparent reorder sort help'; return
      fi
      case $sub in
        show|info)      opts="$__agent_deck_common_opts --resolved" ;;
        create|new)     opts="$__agent_deck_common_opts --parent --default-path --max-concurrent" ;;
        update|set)     opts="$__agent_deck_common_opts --default-path --clear-default-path --max-concurrent" ;;
        delete|rm|remove) opts="$__agent_deck_common_opts --force" ;;
        move|mv)        opts="$__agent_deck_common_opts --force --to-profile" ;;
        reorder|sort)   opts="$__agent_deck_common_opts -u --up -d --down -p --position" ;;
        *)              opts="$__agent_deck_common_opts" ;;
      esac
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      case $sub in
        create|new) return ;;
        move|mv)
          (( npos == 2 )) && { __agent_deck_dyn sessions; return; }
          (( npos == 3 )) && { __agent_deck_dyn groups; return; }
          return ;;
        change|reparent)
          (( npos == 2 || npos == 3 )) && __agent_deck_dyn groups
          return ;;
        list|ls) return ;;
        *)
          (( npos == 2 )) && __agent_deck_dyn groups
          return ;;
      esac ;;
    worktree|wt)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'list ls info finish cleanup help'; return
      fi
      case $sub in
        finish)  opts='--json --into --no-merge --keep-branch --force --abort' ;;
        cleanup) opts='--json --force' ;;
        *)       opts='--json' ;;
      esac
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      (( npos == 2 )) && [[ $sub == info || $sub == finish ]] && __agent_deck_dyn sessions
      return ;;
    remote)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'add remove rm list ls sessions attach rename update'; return
      fi
      case $sub in
        add) opts='--agent-deck-path --profile' ;;
        *)   opts='--json' ;;
      esac
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      case $sub in
        add) return ;;
        attach|rename)
          (( npos == 2 )) && { __agent_deck_dyn remotes; return; }
          (( npos == 3 )) && { __agent_deck_dyn remote-sessions "$sub2"; return; }
          return ;;
        *)
          (( npos == 2 )) && __agent_deck_dyn remotes
          return ;;
      esac ;;
    conductor)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'setup teardown status list move migrate-dir help'; return
      fi
      case $sub in
        setup)
          opts='--json --agent --description --heartbeat --no-heartbeat
                --heartbeat-idle-minutes --heartbeat-rules-md --instructions-md
                --shared-instructions-md --policy-md --shared-policy-md --claude-md
                --shared-claude-md --no-clear-on-compact --env --env-file' ;;
        teardown)    opts='--json --all --remove' ;;
        list)        opts='--json --profile' ;;
        move)        opts="$__agent_deck_common_opts --to-profile --force" ;;
        migrate-dir) opts='--json --apply --from --force' ;;
        *)           opts='--json' ;;
      esac
      [[ $cur == -* ]] && { __agent_deck_words "$opts"; return; }
      case $sub in
        migrate-dir) (( npos == 2 )) && __agent_deck_dirs; return ;;
        list)        return ;;
        *)           (( npos == 2 )) && __agent_deck_dyn conductors; return ;;
      esac ;;
    profile)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'list create delete default help'; return
      fi
      [[ $cur == -* ]] && { __agent_deck_words "$__agent_deck_common_opts"; return; }
      case $sub in
        delete|default) (( npos == 2 )) && __agent_deck_dyn profiles ;;
      esac
      return ;;
    web)
      __agent_deck_words '--listen --token --read-only --no-tui --push
        --push-test-every --push-vapid-subject --insecure-bind'; return ;;
    costs)
      if (( npos == 1 )) && [[ $cur != -* ]]; then __agent_deck_words 'sync summary recompute'; return; fi
      case $sub in
        summary) __agent_deck_words '--json' ;;
        *)       __agent_deck_words '-n --dry-run' ;;
      esac
      return ;;
    watcher)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'create import start stop list status test routes install-skill help'; return
      fi
      case $sub in
        create)
          [[ $cur == -* ]] && { __agent_deck_words '--name --port --secret --secret-file --topic'; return; }
          (( npos == 2 )) && { __agent_deck_words 'webhook ntfy github slack'; return; }
          return ;;
        list|status|routes) __agent_deck_words '--json'; return ;;
      esac
      return ;;
    openclaw|oc)
      if (( npos == 1 )) && [[ $cur != -* ]]; then
        __agent_deck_words 'sync bridge status list send help'; return
      fi
      case $sub in
        bridge) __agent_deck_words '--agent --name' ;;
        send)   __agent_deck_words '--agent' ;;
        *)      __agent_deck_words '--json' ;;
      esac
      return ;;
    inbox)
      if (( npos == 1 )) && [[ $cur != -* ]]; then __agent_deck_words 'drain'; return; fi
      [[ $cur == -* ]] && { __agent_deck_words '--json'; return; }
      (( npos == 2 )) && __agent_deck_dyn sessions
      return ;;
    hooks|codex-hooks|gemini-hooks|hermes-hooks|cursor-hooks)
      (( npos == 1 )) && __agent_deck_words 'install uninstall status'
      return ;;
    telegram-doctor)
      __agent_deck_words '--json --quiet'; return ;;
    update)
      __agent_deck_words '--check --version'; return ;;
    migrate-paths)
      __agent_deck_words '--dry-run --force'; return ;;
    uninstall)
      __agent_deck_words '--dry-run --keep-data --keep-tmux-config -y'; return ;;
    help)
      (( npos == 1 )) && __agent_deck_words "$__agent_deck_commands"
      return ;;
  esac

  return 0
}

complete -F _agent_deck agent-deck
