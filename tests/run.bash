#!/usr/bin/env bash
# Self-validating suite for the bash completion. Sources bash-completion and the
# completion once, then runs every case in one process — one bash startup for the
# whole suite instead of one per case.
#
#   tests/run.bash            # run all cases, exit non-zero on any failure
#   tests/run.bash session    # only cases whose command line matches 'session'
#
# Cases that need live sessions run against a throwaway profile, created and
# removed here, so a developer's real sessions are never touched.
set -uo pipefail

for bash_completion in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
  # Loading bash-completion also loads /etc/bash_completion.d/*, some of which
  # chatter on stdout; keep the suite output clean.
  # shellcheck disable=SC1090,SC1091  # path is chosen at runtime
  [[ -r $bash_completion ]] && { source "$bash_completion" >/dev/null 2>&1; break; }
done

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../bash/agent-deck.bash disable=SC1091
source "$here/../bash/agent-deck.bash"

readonly TEST_PROFILE=_completion_suite
readonly TEST_SESSION='Comp Test'
# A title that starts with a dash is legal, and is the only way a positional
# candidate can prefix-match a word the user started with '-'. That makes it the
# fixture that can tell "we stopped at options" apart from "we fell through".
readonly TEST_DASH_SESSION='-dash-session'

setup_fixture() {
  command -v agent-deck >/dev/null 2>&1 || return 0
  agent-deck -p "$TEST_PROFILE" add -t "$TEST_SESSION" -c claude /tmp >/dev/null 2>&1
  agent-deck -p "$TEST_PROFILE" add -t "$TEST_DASH_SESSION" -c claude /tmp >/dev/null 2>&1
}

teardown_fixture() {
  command -v agent-deck >/dev/null 2>&1 || return 0
  agent-deck -p "$TEST_PROFILE" remove "$TEST_SESSION" >/dev/null 2>&1
  agent-deck -p "$TEST_PROFILE" remove "$TEST_DASH_SESSION" >/dev/null 2>&1
  printf 'y\n' | agent-deck profile delete "$TEST_PROFILE" >/dev/null 2>&1
}

# Reproduce how readline splits the line: a backslash-escaped or quoted word is
# a single COMP_WORDS element, and bash keeps it in its escaped form (verified
# against a real interactive bash).
candidates_for() {
  local line=$1 word
  local -a line_words=()
  if [[ $line == *\\* || $line == *\"* || $line == *\'* ]]; then
    eval "set -- $line"
    for word in "$@"; do line_words+=( "$(printf '%q' "$word")" ); done
  else
    read -r -a line_words <<< "$line"
  fi
  [[ $line == *' ' ]] && line_words+=('')

  COMP_WORDS=("${line_words[@]}")
  COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
  COMP_LINE=$line
  COMP_POINT=${#line}
  COMPREPLY=()
  _agent_deck
  printf '%s ' "${COMPREPLY[@]}"
}

passed=0 failed=0 skipped=0
filter=${1-}

have_agent_deck() { command -v agent-deck >/dev/null 2>&1; }

# expect '<partial command line>' '<substring the candidates must contain>'
expect() {
  local line=$1 wanted=$2 got
  [[ -n $filter && $line != *"$filter"* ]] && return 0
  got=$(candidates_for "$line")
  if [[ $got == *"$wanted"* ]]; then
    (( passed++ ))
    printf 'ok   %s\n' "$line"
  else
    (( failed++ ))
    printf 'FAIL %s\n       want substring: %s\n       got:            %s\n' "$line" "$wanted" "${got:-<none>}"
  fi
}

# expect_live / expect_empty_live — same, but skipped when agent-deck is not
# installed, because their candidates come from the running CLI. CI has no
# agent-deck, and a skip there is honest where a pass would not be.
expect_live() {
  if ! have_agent_deck; then
    [[ -n $filter && $1 != *"$filter"* ]] && return 0
    (( skipped++ )); printf 'skip %s (needs agent-deck)\n' "$1"; return 0
  fi
  expect "$@"
}

expect_empty_live() {
  if ! have_agent_deck; then
    [[ -n $filter && $1 != *"$filter"* ]] && return 0
    (( skipped++ )); printf 'skip %s (needs agent-deck)\n' "$1"; return 0
  fi
  expect_empty "$@"
}

# expect_empty '<partial command line>'   — deliberately offers nothing
expect_empty() {
  local line=$1 got
  [[ -n $filter && $line != *"$filter"* ]] && return 0
  got=$(candidates_for "$line")
  if [[ -z ${got// /} ]]; then
    (( passed++ ))
    printf 'ok   %s (no candidates)\n' "$line"
  else
    (( failed++ ))
    printf 'FAIL %s\n       want: no candidates\n       got:  %s\n' "$line" "$got"
  fi
}

setup_fixture
trap teardown_fixture EXIT

# commands and subcommand trees
expect 'agent-deck '                          'add launch try'
expect 'agent-deck se'                        'session'
expect 'agent-deck session '                  'start stop remove'
expect 'agent-deck session st'                'start stop'
expect 'agent-deck mcp '                      'list ls attached attach detach server'
expect 'agent-deck mcp server '               'start stop status'
expect 'agent-deck skill source '             'list add remove'
expect 'agent-deck group re'                  'reorder'
expect 'agent-deck worktree '                 'list ls info finish cleanup'
expect 'agent-deck profile '                  'list create delete default'
expect 'agent-deck watcher create '           'webhook ntfy github slack'
expect 'agent-deck inbox '                    'drain'
expect 'agent-deck codex-hooks '              'install uninstall status'
expect 'agent-deck help '                     'add launch'

# option lists
expect 'agent-deck session start --'          '--message-file'
expect 'agent-deck fleet recover --'          '--auth-halt-after'
expect 'agent-deck conductor teardown --'     '--all --remove'
expect 'agent-deck web --'                    '--insecure-bind'
expect 'agent-deck update --'                 '--check --version'
expect 'agent-deck -'                         '--profile'

# enums and option values
expect 'agent-deck add -c '                   'kiro-cli'
expect 'agent-deck conductor setup --agent '  'claude'
expect 'agent-deck add --location '           'sibling subdirectory'
expect 'agent-deck session search --tier '    'instant balanced auto'
expect 'agent-deck session approve x --choice ' 'once always session'
expect 'agent-deck session approve x '        'once always session'
expect 'agent-deck session set-title-lock x ' 'on off'
expect_live 'agent-deck skill list --source ' 'claude-global'
expect 'agent-deck session set x '            'title path command'

# free-text options must not fall back to filename completion
expect_empty 'agent-deck add -t '
expect_empty 'agent-deck session send-keys x --named-key '
expect_empty 'agent-deck launch --model '
# Typing a flag completes flags and stops there. This pins the explicit
# `return 0` in __agent_deck_offer_options: without it the helper inherits
# compgen's "no match" status and falls through to positional completion, which
# for `-d` reaches the dash-titled fixture session. Anything whose prefix cannot
# match a positional candidate (`--zz`) passes either way and pins nothing.
expect_empty_live "agent-deck -p $TEST_PROFILE session start -d"
expect_empty 'agent-deck web --zz'
expect_empty 'agent-deck session start --zz'

# Sanity check on the case above: the fixture session really is completable when
# it is a positional rather than a flag.
expect_live "agent-deck -p $TEST_PROFILE session start " '-dash-session'

# profile-scoped dynamic values, including positionals past an escaped title
expect_live "agent-deck -p $TEST_PROFILE session start "          'Comp\ Test'
expect_live "agent-deck -p $TEST_PROFILE remove "                 'Comp\ Test'
expect_live "agent-deck -p $TEST_PROFILE session set Comp\\ Test " 'title path command'
expect_live "agent-deck -p $TEST_PROFILE group move Comp\\ Test "  'tmp'
expect_live "agent-deck -p $TEST_PROFILE --select "                'Comp\ Test'
expect_live 'agent-deck -p '                                       "$TEST_PROFILE"

if (( skipped )); then
  printf '\n%d passed, %d failed, %d skipped (no agent-deck on PATH)\n' \
    "$passed" "$failed" "$skipped"
else
  printf '\n%d passed, %d failed\n' "$passed" "$failed"
fi
(( failed == 0 ))
