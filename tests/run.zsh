#!/usr/bin/env zsh
# Self-validating suite for the zsh completion. zsh needs a real terminal to
# complete, so this drives one interactive zsh through zsh/zpty and reuses that
# single pty for every case.
#
#   tests/run.zsh            # run all cases, exit non-zero on any failure
#   tests/run.zsh session    # only cases whose command line matches 'session'
#
# Cases that need live sessions run against a throwaway profile, created and
# removed here, so a developer's real sessions are never touched.

zmodload zsh/zpty

local REPO=${0:A:h:h}
local FILTER=${1-}
local TEST_PROFILE=_completion_suite
local TEST_SESSION='Comp Test'
integer PASSED=0 FAILED=0 SKIPPED=0

have_agent_deck() { (( $+commands[agent-deck] )) }

# expect_live — same as expect, but skipped when agent-deck is not installed,
# because the candidates come from the running CLI. CI has no agent-deck, and a
# skip there is honest where a pass would not be.
expect_live() {
  if ! have_agent_deck; then
    [[ -n $FILTER && $1 != *$FILTER* ]] && return 0
    (( SKIPPED++ )); print -r -- "skip $1 (needs agent-deck)"; return 0
  fi
  expect "$@"
}

setup_fixture() {
  (( $+commands[agent-deck] )) || return 0
  agent-deck -p $TEST_PROFILE add -t $TEST_SESSION -c claude /tmp >/dev/null 2>&1
}

teardown_fixture() {
  (( $+commands[agent-deck] )) || return 0
  agent-deck -p $TEST_PROFILE remove $TEST_SESSION >/dev/null 2>&1
  print -r -- y | agent-deck profile delete $TEST_PROFILE >/dev/null 2>&1
}

drain() {
  local acc="" chunk
  while zpty -r -t comp chunk 2>/dev/null; do acc+=$chunk; done
  print -rn -- $acc
}

# PS1 must contain no spaces and no '>': zpty parses its own argv, and a redirect
# character makes it fail with a parse error.
start_shell() {
  zpty -b comp env TERM=dumb PS1=PROMPT zsh -f -i
  zpty -w comp "fpath=($REPO/zsh \$fpath)"
  zpty -w comp "autoload -Uz compinit && compinit -u -D"
  zpty -w comp "zstyle ':completion:*' menu no"
  zpty -w comp "zstyle ':completion:*:descriptions' format '--- %d ---'"
  zpty -w comp "LISTMAX=500"
  sleep 1
  drain >/dev/null
}

candidates_for() {
  zpty -w -n comp "$1"
  sleep 0.3
  drain >/dev/null
  zpty -w -n comp $'\t'
  sleep 2
  local out="$(drain)"
  zpty -w -n comp $'\C-c'      # abandon the line, keep the shell for the next case
  sleep 0.2
  drain >/dev/null
  print -r -- ${out//$'\r'/}
}

# expect '<partial command line>' '<substring the candidates must contain>'
expect() {
  local line=$1 wanted=$2 got
  [[ -n $FILTER && $line != *$FILTER* ]] && return 0
  got=$(candidates_for "$line")
  if [[ $got == *$wanted* ]]; then
    (( PASSED++ )); print -r -- "ok   $line"
  else
    (( FAILED++ ))
    print -r -- "FAIL $line"
    print -r -- "       want substring: $wanted"
    print -r -- "       got:            ${${got//$'\n'/ }[1,160]}"
  fi
}

setup_fixture
start_shell
trap 'zpty -d comp 2>/dev/null; teardown_fixture' EXIT INT

# zsh lists one candidate per line with its description, so assert on a
# description rather than on adjacent candidate names.
expect 'agent-deck '                              '-- add a new session'
expect 'agent-deck session '                      'set-transition-notify'
expect 'agent-deck session start -'               '--message-file'
expect 'agent-deck mcp '                          'attach'
expect 'agent-deck skill source '                 'add'
expect 'agent-deck group re'                      'reorder'
expect 'agent-deck worktree '                     'finish'
expect 'agent-deck add -c '                       'kiro-cli'
expect 'agent-deck add --location '               'subdirectory'
expect 'agent-deck session search --tier '        'balanced'
expect 'agent-deck session approve x '            'always'
expect 'agent-deck fleet recover --'              '--auth-halt-after'
expect 'agent-deck web --'                        '--insecure-bind'
expect_live 'agent-deck skill list --source '     'claude-global'
expect_live "agent-deck -p $TEST_PROFILE session start " 'Comp Test'
expect_live "agent-deck -p $TEST_PROFILE -g "      'tmp'
expect "agent-deck -p $TEST_PROFILE session set Comp\\ Test " 'idle-timeout'

print -r -- ""
if (( SKIPPED )); then
  print -r -- "$PASSED passed, $FAILED failed, $SKIPPED skipped (no agent-deck on PATH)"
else
  print -r -- "$PASSED passed, $FAILED failed"
fi
(( FAILED == 0 ))
